#!/usr/bin/env bash
#
# logger.sh — Writes structured (JSON-ish) application logs.
# Demonstrates a "well-behaved" service that ships logs to /var/log/linux-ops-lab
# and also to stdout (picked up by journald).
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/app.log"

mkdir -p "$LAB_LOG_DIR"

trap 'echo "[logger] exiting"; exit 0' INT TERM

LEVELS=(INFO INFO INFO INFO WARN INFO DEBUG INFO ERROR)
EVENTS=(
  "user.login"
  "cache.miss"
  "db.query"
  "queue.enqueue"
  "queue.dequeue"
  "external.api.call"
  "session.expired"
  "feature.flag.evaluated"
)

i=0
while true; do
  i=$((i + 1))
  level="${LEVELS[$(( RANDOM % ${#LEVELS[@]} ))]}"
  event="${EVENTS[$(( RANDOM % ${#EVENTS[@]} ))]}"
  uid=$((RANDOM % 9000 + 1000))
  line=$(printf '{"ts":"%s","level":"%s","event":"%s","seq":%d,"uid":%d}' \
    "$(date --iso-8601=seconds)" "$level" "$event" "$i" "$uid")
  echo "$line" | tee -a "$LOG"
  sleep 2
done
