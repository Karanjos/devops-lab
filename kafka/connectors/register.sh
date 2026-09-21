#!/bin/sh
# Registers every *.json file in this folder as a connector (file name = connector name).
# PUT /connectors/<name>/config is idempotent: it creates the connector or updates it.
set -eu

CONNECT_URL="${CONNECT_URL:-http://kafka-connect:8083}"

for file in /connectors/*.json; do
  name="$(basename "$file" .json)"
  echo "Registering connector: $name"
  curl -fsS -X PUT \
       -H 'Content-Type: application/json' \
       --data @"$file" \
       "$CONNECT_URL/connectors/$name/config"
  echo
done
echo "Done."
