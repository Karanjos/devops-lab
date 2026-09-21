#!/usr/bin/env bash
# End-to-end smoke test for the local stack. Also a first bash-scripting exercise:
# read it, then extend it (see docs/phase-2). Requires: curl, jq, docker compose.
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"
CONNECTOR="${CONNECTOR:-orders-jdbc-sink}"
TRIES="${TRIES:-30}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mFAIL:\033[0m %s\n' "$*" >&2; exit 1; }

for tool in curl jq docker; do
  command -v "$tool" >/dev/null || fail "'$tool' is required but not installed"
done

# retry <description> <command...>: run the command until it succeeds or TRIES is exhausted
retry() {
  local what="$1"; shift
  for ((i = 1; i <= TRIES; i++)); do
    if "$@" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  fail "timed out waiting for: $what"
}

log "1/5 nginx is up"
retry "nginx /healthz" curl -fs "$BASE_URL/healthz"

log "2/5 API is healthy (through nginx -> tomcat)"
retry "API health" curl -fs "$BASE_URL/api/actuator/health"

log "3/5 place an order"
response="$(curl -fsS -X POST "$BASE_URL/api/orders" \
  -H 'Content-Type: application/json' \
  -d '{"customer":"smoke-test","item":"Test widget","quantity":3}')"
id="$(jq -r '.id' <<<"$response")"
[[ "$id" != "null" && -n "$id" ]] || fail "no order id in response: $response"
echo "    order id: $id"

log "4/5 order becomes PROCESSED (API -> Kafka -> consumer -> DB)"
is_processed() { [[ "$(curl -fs "$BASE_URL/api/orders/$id" | jq -r '.status')" == "PROCESSED" ]]; }
retry "order $id to reach PROCESSED" is_processed

log "5/5 order reaches the report table (Kafka Connect JDBC sink)"
state="$(curl -fs "$CONNECT_URL/connectors/$CONNECTOR/status" | jq -r '.connector.state')"
echo "    connector state: $state"
in_report() {
  [[ "$(docker compose exec -T postgres psql -U orders -d orders -tAc \
      "select count(*) from orders_report where id = '$id'")" == "1" ]]
}
retry "order $id in orders_report" in_report

printf '\033[1;32mPASS\033[0m  order %s made it through the whole pipeline\n' "$id"
