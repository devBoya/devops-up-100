#!/usr/bin/env bash
#
# memory-leak.sh — Gradually allocates RAM to simulate a leak.
# Used for Scenario 2: memory pressure.
#
# Designed to grow slowly so students have time to investigate before OOM.
# We cap growth so the VM doesn't die instantly.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/memory-leak.log"

mkdir -p "$LAB_LOG_DIR"

# Allocate ~20MB per tick, every 5s, up to a soft cap of ~600MB.
GROWTH_MB="${LAB_LEAK_GROWTH_MB:-20}"
INTERVAL="${LAB_LEAK_INTERVAL_S:-5}"
SOFT_CAP_MB="${LAB_LEAK_CAP_MB:-600}"

echo "$(date --iso-8601=seconds) [memory-leak] starting growth=${GROWTH_MB}MB interval=${INTERVAL}s cap=${SOFT_CAP_MB}MB" | tee -a "$LOG"

exec python3 -u -c "
import os, sys, time
growth_mb  = int(os.environ.get('GROWTH_MB',  '${GROWTH_MB}'))
interval   = int(os.environ.get('INTERVAL',   '${INTERVAL}'))
cap_mb     = int(os.environ.get('SOFT_CAP_MB','${SOFT_CAP_MB}'))
blob = bytearray()
used = 0
while True:
    if used < cap_mb:
        blob.extend(b'\x00' * (growth_mb * 1024 * 1024))
        used += growth_mb
        # Touch pages so the kernel actually commits them.
        for i in range(0, len(blob), 4096):
            blob[i] = 1
        sys.stdout.write('[memory-leak] allocated_mb=%d\n' % used)
        sys.stdout.flush()
    else:
        sys.stdout.write('[memory-leak] holding at cap=%dMB\n' % used)
        sys.stdout.flush()
    time.sleep(interval)
"
