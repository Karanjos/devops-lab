# Phase 2: containers, Nginx, Tomcat, Kafka, Kafka Connect

**Goal:** run the whole system with `docker compose up`, and understand every moving part well enough to debug it.

## Start it
```bash
make up          # builds 3 images (backend, frontend, connect) and pulls postgres/kafka
make ps          # everything should end up "healthy"; connector-init exits after registering
make smoke       # end-to-end check
```
Open <http://localhost:8080>, place orders, and watch the *Processing → Processed* transition.

## Tour of the stack

### The images (multi-stage builds)
- `backend/Dockerfile`: stage 1 builds the WAR with Maven, stage 2 is a small Tomcat image with only the WAR.
  Compare sizes: `docker images | grep devops-lab`. Then `docker history devops-lab-backend`.
  Edit one Java file and rebuild; notice that the dependency layer is cached. Now edit `pom.xml`; what gets rebuilt?
- `frontend/Dockerfile`: Node builds the static files, Nginx serves them. Node is not in the final image.

### Tomcat
```bash
docker compose exec backend bash
ls /usr/local/tomcat/webapps /usr/local/tomcat/conf /usr/local/tomcat/logs
grep -n "Connector" /usr/local/tomcat/conf/server.xml     # port 8080, protocol, threads
ps aux | grep java                                        # see CATALINA_OPTS applied
```
The app is deployed as `ROOT.war`, which is why the URL has no context path. Deploy it as `orders.war` in a scratch container
and see how the URLs change (`/orders/api/orders`); that is the classic Tomcat gotcha.

### Nginx
```bash
docker compose exec frontend cat /etc/nginx/conf.d/default.conf   # the rendered config
docker compose exec frontend nginx -t                              # validate config
curl -I localhost:8080/assets/                                     # cache headers
curl -s localhost:8080/healthz
```
`nginx.conf.template` contains `${BACKEND_HOST}`; the image substitutes it at startup. That is how the same image works in
compose and later in Kubernetes.

### Kafka (KRaft, no ZooKeeper)
```bash
make topics
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --describe --topic orders.created
# In one terminal, watch events arrive:
docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka:9092 --topic orders.created --from-beginning --property print.key=true
# In another, check the consumer group and its lag:
docker compose exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server kafka:9092 --describe --group order-processor
```
Why are there **two** advertised listeners in `docker-compose.yml`? (Containers reach Kafka at `kafka:9092`;
your laptop at `localhost:29092`. A broker must advertise an address the *client* can reach.)

### Kafka Connect
```bash
curl -s localhost:8083/connector-plugins | jq '.[].class' | grep -i jdbc
curl -s localhost:8083/connectors | jq
curl -s localhost:8083/connectors/orders-jdbc-sink/status | jq
make psql     # then:  select * from orders_report order by processed_at desc limit 5;
```
The connector definition is `kafka/connectors/orders-jdbc-sink.json`; `connector-init` registers it through the REST API.
The backend's `orders.processed` messages carry a schema next to the payload (look at `OrderEventPublisher.publishProcessed`),
because the JSON converter needs it to create table columns.

## Exercises
1. **Break Kafka.** `docker compose stop kafka`, then place an order. What does the UI show, what do the backend logs say?
   Start Kafka again. Does the order get processed? Why or why not? (Hint: think about what was already saved and what was not published.)
2. **Break the consumer.** Add `throw new RuntimeException("boom")` to `OrderEventConsumer`, rebuild, and watch retries in the logs.
   How does Spring Kafka's default error handler behave? Research dead-letter topics.
3. **Break Connect.** `docker compose stop kafka-connect`, place 5 orders, start it again. Where did the 5 rows come from?
   (Consumer offsets. Inspect them with `kafka-consumer-groups.sh --group connect-orders-jdbc-sink`.)
4. **Tune Tomcat.** Copy `server.xml` out of the container, change `maxThreads`, mount it back with a `volumes:` entry, restart, verify.
5. **Extend the smoke test.** Make it fail with a clear message if Connect's task state is not `RUNNING`; add a `--count N` flag that places N orders.
6. **Scale.** `docker compose up -d --scale backend=2` (remove the fixed host port on backend first). Watch partitions get split across the two consumers.
7. **Secrets.** The DB password is in a connector JSON and in compose. Research Kafka Connect config providers and `.env` files. What is the
   least-bad improvement for a local lab? What would you do in Kubernetes?

8. **Persistence.** Kafka has no volume here, so `make down` wipes its topics while Postgres keeps its data. Add a named volume for
   Kafka's data directory, find the right path with `docker compose exec kafka ls /var/lib/kafka`, and prove that topics survive a restart.

## You're done when
- `make smoke` passes from a clean state (`make clean && make up`).
- You can draw the data flow from memory and say which port and hostname each hop uses.
- You can explain why the order is saved to the database *before* the Kafka event is published, and what could still go wrong
  (the transactional outbox pattern is the industry answer).
