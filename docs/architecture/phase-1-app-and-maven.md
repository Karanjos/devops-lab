# Phase 1: run the app locally, learn Maven

**Goal:** get the React UI, the Spring Boot API and PostgreSQL working together on your machine, and understand the Maven build.

**Prereqs:** JDK 21, Maven 3.9+, Node 22, Docker (only to run Postgres). Check with `java -version`, `mvn -v`, `node -v`, `docker -v`.

In this phase Kafka is switched off (`KAFKA_ENABLED=false`): the API processes each order immediately. That keeps Phase 1 small
and lets you see, in Phase 2, exactly what Kafka changes.

## Steps

### 1. Start PostgreSQL
```bash
make db                      # = docker compose up -d postgres
docker compose ps            # wait for "healthy"
ss -ltnp | grep 5432         # Linux: who is listening on 5432?
```

### 2. Run the API
```bash
cd backend
KAFKA_ENABLED=false mvn spring-boot:run
```
It listens on **8081** (see `server.port` in `application.yml`).
```bash
curl -s localhost:8081/api/actuator/health
curl -s -X POST localhost:8081/api/orders -H 'Content-Type: application/json' \
     -d '{"customer":"Asha","item":"Notebook","quantity":2}' | jq
curl -s localhost:8081/api/orders | jq
```
Inspect the data: `make psql`, then `\dt` and `select * from orders;`.

### 3. Run the UI
```bash
make frontend-dev            # http://localhost:5173
```
Vite proxies `/api` to `:8081` (see `frontend/vite.config.js`), so there is no CORS to configure.

### 4. Understand the Maven build
Run each command and read what it does.
```bash
cd backend
mvn validate                 # check the POM
mvn compile                  # target/classes
mvn test                     # runs OrderServiceTest
mvn package                  # target/orders-api.war
mvn dependency:tree | less   # what Spring Boot pulled in, and why
mvn help:effective-pom | less  # the POM after inheriting from spring-boot-starter-parent
unzip -l target/orders-api.war | less  # what is inside a WAR (look at WEB-INF/)
```
Lifecycle to remember: `validate → compile → test → package → verify → install → deploy`. Running a phase runs all earlier ones.

## Concepts to be able to explain
- Why is the packaging `war`, and why is `spring-boot-starter-tomcat` marked `provided`?
- What does the `spring-boot-starter-parent` give you? (dependency versions, plugin config)
- Why does the API return `202 Accepted` and not `201 Created`?
- What is `ddl-auto: update` doing, and why should you not use it in production?

## Exercises
1. **Add a field.** Add `notes` (optional, max 200 chars) to the entity, request, response and form. Watch Hibernate add the column.
2. **Add a test.** Write a controller test with `@WebMvcTest` that checks a blank customer returns `400`.
3. **Maven profile.** Add a `<profile>` called `fast` that sets `skipTests=true`; run `mvn package -Pfast`.
4. **Break it:** stop Postgres (`docker compose stop postgres`) while the API is running. What do the logs say? What does
   `/api/actuator/health` return? Start it again and see whether the API recovers by itself.
5. **Break it:** run with a wrong DB password using `DB_PASSWORD=wrong mvn spring-boot:run`. Find the exact line in the log that explains why.

## You're done when
- You can place an order in the UI and see it in Postgres.
- `mvn package` produces `target/orders-api.war` and you can list its contents.
- You can explain each Maven lifecycle phase and where your tests run.
