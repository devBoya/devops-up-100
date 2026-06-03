#!/usr/bin/env bash
#
# worker.sh — Pretends to process jobs off an in-memory queue.
# Logs each job, sleeps to simulate work.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/worker.log"

mkdir -p "$LAB_LOG_DIR"

log() {
  printf '%s [worker] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG"
}

trap 'log "shutting down"; exit 0' INT TERM

log "worker starting"

JOB_TYPES=(invoice.process payment.settle email.send report.generate webhook.deliver)
i=0
while true; do
  i=$((i + 1))
  job="${JOB_TYPES[$(( RANDOM % ${#JOB_TYPES[@]} ))]}"
  duration=$(( RANDOM % 4 + 1 ))
  log "job_id=$i type=$job picked_up duration_s=$duration"
  sleep "$duration"
  log "job_id=$i type=$job completed"
done
