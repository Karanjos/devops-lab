# Break-it playbook: exercising each Phase 3 script

Put this file at `docs/break-it-playbook.md` in your repo. Each section breaks one part of the
stack on purpose, tells you which script should notice, and how to put things back. Do them one
at a time, not all at once, so you know which change caused which effect.

General rule before you start any scenario:
```bash
docker compose ps   # confirm everything is healthy before you break anything
```
And after every scenario, the "Undo" step, so you start the next one from a clean baseline.

---

## 1. `healthcheck.sh` — take down one dependency at a time

### 1a. Nginx down
```bash
docker compose stop frontend
./scripts/healthcheck.sh
```
Expect: step 1 (nginx) fails, everything else still gets checked and reported.
```bash
docker compose start frontend    # undo
```

### 1b. Postgres down
```bash
docker compose stop postgres
./scripts/healthcheck.sh
```
Expect: step 3 (postgres port) fails. The API step may also start failing after a few seconds,
once the backend's connection pool runs out of usable connections — worth watching both.
```bash
docker compose start postgres    # undo
```

### 1c. Kafka down
```bash
docker compose stop kafka
./scripts/healthcheck.sh
```
Expect: step 4 (Kafka port) fails, and step 5 (Connect) likely fails too, since Connect itself
depends on Kafka.
```bash
docker compose start kafka       # undo
```

### 1d. Kafka Connect down
```bash
docker compose stop kafka-connect
./scripts/healthcheck.sh
```
Expect: only step 5 fails, the rest stay healthy, since nothing else in this app depends on
Connect directly.
```bash
docker compose start kafka-connect   # undo
```

### 1e. Port collision (simulate the Jenkins situation from earlier)
```bash
docker run -d --name port-hog -p 8088:80 nginx:alpine
./scripts/healthcheck.sh
```
Expect: `docker compose up` for frontend would now fail if you tried to (re)create it — this
scenario is more about understanding *why* than what healthcheck.sh reports, since it only
checks things that are already running.
```bash
docker rm -f port-hog             # undo
```

### 1f. Missing tool
```bash
sudo mv "$(which nc)" /tmp/nc-hidden
./scripts/healthcheck.sh
```
Expect: the tool-check loop at the top catches this before any real check runs.
```bash
sudo mv /tmp/nc-hidden "$(command -v nc || echo /usr/bin/nc)"   # undo — see note below
```
Note: if `which nc` fails after hiding it, restore with `sudo apt install --reinstall -y netcat-openbsd` instead.

---

## 2. `create-topics.sh` — idempotency and mismatches

### 2a. Run it twice with identical arguments (the actual idempotency test)
```bash
./scripts/create-topics.sh -t orders.test -p 3 -r 1
./scripts/create-topics.sh -t orders.test -p 3 -r 1
```
Expect: both succeed, second run changes nothing, no error.

### 2b. Run it again with different partition count
```bash
./scripts/create-topics.sh -t orders.test -p 6 -r 1
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --describe --topic orders.test
```
Expect: still shows the original 3 partitions — `--if-not-exists` silently ignores the mismatch.
This is the behavior worth remembering, not a bug.

### 2c. Missing required flag
```bash
./scripts/create-topics.sh -p 3
```
Expect: usage message, exit code 1, no topic created.

### 2d. Point it at a broker that doesn't exist
```bash
KAFKA_BOOTSTRAP=localhost:1 ./scripts/create-topics.sh -t orders.test2
```
Expect: a connection/timeout error from the Kafka CLI itself.

Undo:
```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --delete --topic orders.test
```

---

## 3. `backup-db.sh` / `restore-db.sh` — the ones you must test for real

An untested backup is not a backup. Do the full destroy-and-recover cycle at least once.

### 3a. Baseline backup
```bash
./scripts/backup-db.sh
ls -lh ~/devops-labs-backups/    # note the exact filename it prints
```

### 3b. Destroy data on purpose
```bash
docker compose exec postgres psql -U orders -d orders -c "DELETE FROM orders;"
docker compose exec postgres psql -U orders -d orders -c "SELECT count(*) FROM orders;"   # should be 0
```

### 3c. Restore and confirm recovery
```bash
./scripts/restore-db.sh ~/devops-labs-backups/<the-exact-filename-from-3a>.sql.gz
docker compose exec postgres psql -U orders -d orders -c "SELECT count(*) FROM orders;"   # should be back
curl -s http://localhost:8088/api/orders | jq
```

### 3d. Restore while the backend is actively using the database (the "already exists" bug from earlier)
```bash
docker compose start backend    # make sure it's running and holding connections
docker compose exec postgres psql -U orders -d orders -c "
    SELECT count(*) FROM pg_stat_activity WHERE datname = 'orders';"
./scripts/restore-db.sh ~/devops-labs-backups/<any-backup>.sql.gz
```
Expect: the script stops the backend itself first, terminates lingering connections, then
proceeds. If you comment out the `docker compose stop backend` line temporarily, you can
reproduce the original `database "orders" is being accessed by other users` error on purpose,
then put the line back and confirm it's fixed.

### 3e. Corrupt the backup file, on purpose
```bash
cp ~/devops-labs-backups/<any-backup>.sql.gz /tmp/corrupt.sql.gz
truncate -s -100 /tmp/corrupt.sql.gz     # chop the end off
./scripts/restore-db.sh /tmp/corrupt.sql.gz
```
Expect: `gunzip` or `psql` reports an error partway through. Notice the backend was already
stopped and the database already dropped by this point — this is a good moment to think about
whether `restore-db.sh` should back up the *current* state before attempting a restore, so a
bad restore doesn't leave you worse off than before you started. Consider it an extension
exercise.

### 3f. Retention: prove old backups actually get removed
```bash
KEEP=2 bash -c 'for i in 1 2 3 4; do ./scripts/backup-db.sh; sleep 1; done'
ls ~/devops-labs-backups/
```
Expect: only the newest 2 backups remain.

---

## 4. `logwatch.sh` — you need a real ERROR, not just any failure

The lesson from earlier: deleting a Kafka Connect connector is not an error. Use scenarios that
actually produce `ERROR`-level log lines.

### 4a. Kafka down while the backend tries to publish
```bash
docker compose stop kafka
for i in {1..3}; do
    curl -s -X POST http://localhost:8088/api/orders -H 'Content-Type: application/json' \
        -d '{"customer":"logtest","item":"Widget","quantity":1}' >/dev/null
    sleep 1
done
./scripts/logwatch.sh backend
docker compose start kafka
```
Expect: real ERROR lines from the Kafka producer failing to connect, grouped by minute.

### 4b. Database down while the backend tries to save an order
```bash
docker compose stop postgres
curl -s -X POST http://localhost:8088/api/orders -H 'Content-Type: application/json' \
    -d '{"customer":"logtest2","item":"Gadget","quantity":1}' >/dev/null
./scripts/logwatch.sh backend
docker compose start postgres
```

### 4c. Consumer throws on purpose (from the Phase 2 exercises)
Temporarily add `throw new RuntimeException("boom");` to `OrderEventConsumer.onOrderCreated`,
rebuild, place an order, watch retries pile up as ERROR lines:
```bash
docker compose up -d --build backend
curl -s -X POST http://localhost:8088/api/orders -H 'Content-Type: application/json' \
    -d '{"customer":"logtest3","item":"Thing","quantity":1}' >/dev/null
./scripts/logwatch.sh backend
```
Undo: remove the line, rebuild again.

### 4d. Confirm what does *not* count as an ERROR
```bash
docker compose run --rm connector-init   # re-register, then delete it again
docker compose exec kafka-connect curl -s -X DELETE http://localhost:8083/connectors/orders-jdbc-sink
./scripts/logwatch.sh kafka-connect
```
Expect: no ERROR lines. Confirm this by reading the actual log line Connect produces for the
deletion (`docker compose logs kafka-connect | tail -20`) — notice its log level.

Undo, always re-register the connector when you're done testing:
```bash
docker compose run --rm connector-init
```

---

## 5. `deploy.sh` — a failed build, and a failed health check, are different failures

### 5a. Build failure (should refuse to touch anything running)
```bash
echo "this is not valid java" >> backend/src/main/java/com/devopslab/orders/OrdersApplication.java
./scripts/deploy.sh
docker compose ps    # the OLD containers should still be running, untouched
git checkout backend/src/main/java/com/devopslab/orders/OrdersApplication.java
```

### 5b. Runtime failure (should trigger a real rollback)
```bash
# temporarily edit docker-compose.yml, backend's environment:
#   DB_URL: jdbc:postgresql://postgres:5432/nonexistent_db
./scripts/deploy.sh
```
Expect: the build succeeds, the new container starts, health check never passes, `rollback`
fires, the previous working images come back up.
```bash
git checkout docker-compose.yml   # undo, then redeploy clean
./scripts/deploy.sh
```

### 5c. Confirm the `DEPLOY_STARTED` guard
```bash
docker compose down       # simulate "nothing running yet"
docker rmi devops-lab-backend:previous devops-lab-frontend:previous 2>/dev/null
./scripts/deploy.sh
```
Watch what `rollback` does if triggered before any `:previous` tag exists — it should say
there's nothing to roll back to, rather than failing confusingly.

---

## After every session

```bash
docker compose ps                 # confirm everything is healthy again
BASE_URL=http://localhost:8088 make smoke   # confirm the whole pipeline still works end to end
```

## Keep notes as you go

For each scenario, jot down in your own `NOTES.md`:
- what you expected to happen
- what actually happened
- the exact error text, if it differed from what this playbook predicted
- what you'd change about the script now that you've seen it fail this way

That last line is the part that actually sticks with you.