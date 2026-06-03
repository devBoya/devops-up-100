#!/usr/bin/env bash
#
# permission-bug.sh — Tries to append to a log file labapp doesn't own.
# Used for Scenario 3: Permission denied.
#
# In install.sh we create /var/log/linux-ops-lab owned by labapp.
# The scenario primer (Makefile target `break-permissions`) chowns
# /var/log/linux-ops-lab/permission-bug.log to root:root with mode 0600 — this
# script then fails on every write attempt, which students must diagnose
# via systemctl status / journalctl / ls -l / chown.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
TARGET="$LAB_LOG_DIR/permission-bug.log"

trap 'echo "[permission-bug] exiting"; exit 0' INT TERM

echo "$(date --iso-8601=seconds) [permission-bug] starting; target=$TARGET as $(id -un)"

while true; do
  # Deliberately do NOT swallow the failure — let systemd see a non-zero exit
  # if the write fails. With Restart=on-failure this means students see the
  # service flapping in `systemctl status`.
  if ! echo "$(date --iso-8601=seconds) attempting write" >> "$TARGET" 2>/dev/null; then
    echo "$(date --iso-8601=seconds) [permission-bug] Permission denied writing to $TARGET" >&2
    # Exit non-zero so systemd flags the service as failed.
    exit 1
  fi
  sleep 3
done
