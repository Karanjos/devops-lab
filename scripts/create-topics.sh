#! /usr/bin/env bash
set -euo pipefail

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

error() { printf '\033[1;31mFAIL:\033[0m %s\n' "$*"; }

success() { printf '\033[1;32mPASS\033[0m  %s\n' "$*"; }

KAFKA_BOOTSTRAP="${KAFKA_BOOTSTRAP:-kafka:9092}"

usage() {
    cat <<'EOF'
    Usage: "$0" -t <topic-name> [-p <partitions>] [-r <replication-factor>]
    -t topic-name: Name of the topic to create (required)
    -p partitions: Number of partitions (default: 3)
    -r replication-factor: Replication factor (default: 1)
EOF
    exit 1
}

partitions=3
replication=1
topic=""

while getopts "t:p:r:h" opt; do
    case $opt in
        t) topic="$OPTARG" ;;
        p) partitions="$OPTARG" ;;
        r) replication="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

[[ -z "$topic" ]] && { error "Topic name is required (-t)"; usage; }

log "Creating topic '$topic' (partitions=$partitions, replication=$replication) if it doesn't already exist"

docker compose exec -T kafka "/opt/kafka/bin/kafka-topics.sh" \
    --bootstrap-server "$KAFKA_BOOTSTRAP" \
    --create --if-not-exists \
    --topic "$topic" \
    --partitions "$partitions" \
    --replication-factor "$replication"

log "Done. Current state:"

docker compose exec -T kafka "/opt/kafka/bin/kafka-topics.sh" \
    --bootstrap-server "$KAFKA_BOOTSTRAP" \
    --describe \
    --topic "$topic"