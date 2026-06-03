#!/usr/bin/env bash
#
# scheduler.sh — Runs fake scheduled tasks at regular intervals.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/scheduler.log"

mkdir -p "$LAB_LOG_DIR"

log() {
  printf '%s [scheduler] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG"
}

trap 'log "shutting down"; exit 0' INT TERM

TASKS=(
  "10 cleanup.tmp"
  "20 rotate.logs"
  "30 sync.cache"
  "45 reconcile.balances"
  "60 backup.snapshot"
)

log "scheduler starting"

tick=0
while true; do
  for entry in "${TASKS[@]}"; do
    interval="${entry%% *}"
    task="${entry##* }"
    if (( tick % interval == 0 )); then
      log "tick=$tick running task=$task"
    fi
  done
  sleep 1
  tick=$((tick + 1))
done
