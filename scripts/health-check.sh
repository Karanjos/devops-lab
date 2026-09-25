#!/usr/bin/env bash

set -uo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

error() { printf '\033[1;31mFAIL:\033[0m %s\n' "$*"; }

success() { printf '\033[1;32mPASS\033[0m  %s\n' "$*"; }

BASE_URL="${BASE_URL:-http://localhost:8088}"
TRIES="${TRIES:-5}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
KAFKA_HOST="${KAFKA_HOST:-localhost}"
KAFKA_PORT="${KAFKA_PORT:-29092}"
CONNECT_URL="${CONNECT_URL:-http://localhost:8083}"

results=()

for tool in curl jq docker nc; do
    command -v "$tool" >/dev/null || { error "'$tool' is required but not installed"; results+=("FAIL tool : $tool"); }
done


checkhealth() {
    local name="$1"; shift
    for((i=1; i<=TRIES; i++)); do
        if "$@" >/dev/null 2>&1; then 
        success "$name passed"; 
        results+=("PASS $name");
        return 0; 
        fi
        sleep 1
    done
    error "$name failed";
    results+=("FAIL $name");
    return 1
}

log "1/5 checking nginx health"
checkhealth "nginx /healthz" curl -fs "$BASE_URL/healthz"

log "2/5 checking API health"
if checkhealth "API /api/actuator/health" curl -fs "$BASE_URL/api/actuator/health"; then
    status_line="$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/actuator/health")"
    if [[ "$status_line" == "200" ]]; then
        success "API health check returned 200 OK"
        results+=("PASS API health check returned 200 OK")
    else
        error "API health check returned $status_line"
        results+=("FAIL API health check returned $status_line")
    fi
fi

log "3/5 checking postgres health"
checkhealth "POSTGRES $POSTGRES_HOST $POSTGRES_PORT" nc -z "$POSTGRES_HOST" "$POSTGRES_PORT"

log "4/5 checking Kafka health"
checkhealth "Kafka $KAFKA_HOST $KAFKA_PORT" nc -z "$KAFKA_HOST" "$KAFKA_PORT"

log "5/5 checking Kafka Connect health"
checkhealth "Kafka Connect $CONNECT_URL" curl -fs "$CONNECT_URL"

echo
echo "===== Health check summary ====="
for result in "${results[@]}"; do
    if [[ "$result" == PASS* ]]; then
        success "${result#PASS }"
    else
        error "${result#FAIL }"
    fi
done
echo "================================"

failcount=$(printf '%s\n' "${results[@]}" | grep -c "^FAIL" || true)

if [[ "$failcount" -eq 0 ]]; then
    success "All health checks passed"
    exit 0
else
    error "$failcount health checks failed"
    exit 1
fi

