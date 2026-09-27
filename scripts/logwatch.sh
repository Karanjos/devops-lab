#! /usr/bin/env bash
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; }
success() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

SERVICE="${1:-}"
SINCE="${SINCE:-1h}"

if [[ -n "$SERVICE" ]]; then
    log "Counting ERROR lines per minute for service '$SERVICE', since '$SINCE' ago."
    logs_cmd=(docker compose logs --no-color --since "$SINCE" "$SERVICE")
else
    log "Counting ERROR lines per minute acrross all services, since '$SINCE' ago."
    logs_cmd=(docker compose logs --no-color --since "$SINCE")
fi

error_count=$("${logs_cmd[@]}" | grep -c " ERROR " || true)

if [[ "$error_count" -eq 0 ]]; then
    log "No ERROR lines found in the last '$SINCE'"
    exit 0
fi

success "Found $error_count ERROR line(s). Breakdown by minute:"
echo

"${logs_cmd[@]}" \
    | grep " ERROR " \
    | awk '{print $3, substr($4, 1,5)}' \
    | sort \
    | uniq -c \
    | sort -rn