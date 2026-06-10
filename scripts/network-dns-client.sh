#!/usr/bin/env bash
#
# network-dns-client.sh — Scenario 5: client that resolves lab-network-api.local.
# Periodically curls http://lab-network-api.local:9080/ and logs the result.
# When DNS is broken (break-dns.sh), the hostname points to a non-routable IP.
#
set -Euo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/network-dns-client.log"
TARGET="http://lab-network-api.local:9080/"
INTERVAL=10

trap 'echo "[network-dns-client] received signal, exiting" | tee -a "$LOG"; exit 0' INT TERM

mkdir -p "$LAB_LOG_DIR"

log() {
  printf '%s [network-dns-client] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG"
}

log "starting dns-client, polling $TARGET every ${INTERVAL}s"

while true; do
  if result="$(curl -sf --max-time 3 "$TARGET" 2>&1)"; then
    log "OK: $result"
  else
    log "FAIL: could not reach $TARGET (curl exit=$?)"
  fi
  sleep "$INTERVAL"
done
