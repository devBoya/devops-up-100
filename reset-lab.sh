#!/usr/bin/env bash
#
# reset-lab.sh — Bring the lab back to a clean, healthy state.
# Stops failure services, restores perms, restarts healthy services, prints status.
#
set -Eeuo pipefail

LAB_USER="labapp"
LAB_HOME="/opt/linux-ops-lab"
LAB_LOG_DIR="/var/log/linux-ops-lab"

HEALTHY=(lab-api lab-worker lab-scheduler lab-logger)
BROKEN=(lab-cpu-hog lab-memory-leak lab-permission-bug)

log()  { printf '\033[1;36m[reset]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[reset:warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[reset:err]\033[0m %s\n' "$*" >&2; exit 1; }

trap 'die "reset-lab.sh failed at line $LINENO"' ERR

[[ $EUID -eq 0 ]] || die "Must run as root. Try: sudo $0"

log "Stopping failure services"
for svc in "${BROKEN[@]}"; do
  systemctl stop    "$svc" >/dev/null 2>&1 || true
  systemctl disable "$svc" >/dev/null 2>&1 || true
done

log "Restoring ownership on $LAB_HOME and $LAB_LOG_DIR"
[[ -d "$LAB_HOME"    ]] && chown -R "$LAB_USER:$LAB_USER" "$LAB_HOME"
[[ -d "$LAB_LOG_DIR" ]] && chown -R "$LAB_USER:$LAB_USER" "$LAB_LOG_DIR"
[[ -d "$LAB_LOG_DIR" ]] && chmod 0755 "$LAB_LOG_DIR"

log "Removing generated junk logs in $LAB_LOG_DIR"
if [[ -d "$LAB_LOG_DIR" ]]; then
  find "$LAB_LOG_DIR" -type f -name '*.log' -exec truncate -s 0 {} \;
  find "$LAB_LOG_DIR" -type f -name 'leak-*'      -delete 2>/dev/null || true
  find "$LAB_LOG_DIR" -type f -name 'permission-*' -delete 2>/dev/null || true
fi

log "Resetting failed-state on all units"
systemctl reset-failed >/dev/null 2>&1 || true

log "Restarting healthy services"
for svc in "${HEALTHY[@]}"; do
  systemctl restart "$svc"
done

log "--- Service status ---"
systemctl --no-pager list-units 'lab-*.service' || true

log "Reset complete."
