#!/usr/bin/env bash
#
# cpu-hog.sh — Burns CPU on every core until killed.
# Used for Scenario 1: CPU starvation.
#
# It is *intentionally* greedy. Students should diagnose with top / ps / systemctl.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/cpu-hog.log"

mkdir -p "$LAB_LOG_DIR"

cores="$(nproc)"
echo "$(date --iso-8601=seconds) [cpu-hog] starting on ${cores} core(s)" | tee -a "$LOG"

pids=()
cleanup() {
  echo "$(date --iso-8601=seconds) [cpu-hog] shutting down children" | tee -a "$LOG"
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup INT TERM EXIT

# Per-core busy loops. `awk` keeps CPU at ~100% without allocating memory.
for ((c = 0; c < cores; c++)); do
  awk 'BEGIN { for (;;) {} }' &
  pids+=($!)
done

# Heartbeat so journald shows the service is alive
while true; do
  echo "$(date --iso-8601=seconds) [cpu-hog] still burning (children=${#pids[@]})" >> "$LOG"
  sleep 10
done
