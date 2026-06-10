#!/usr/bin/env bash
#
# uninstall.sh — Tear down the linux-ops-lab-week1 environment.
#
set -Eeuo pipefail

LAB_USER="labapp"
LAB_HOME="/opt/linux-ops-lab"
LAB_LOG_DIR="/var/log/linux-ops-lab"

log() { printf '\033[1;36m[uninstall]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[uninstall:err]\033[0m %s\n' "$*" >&2; exit 1; }

trap 'die "uninstall.sh failed at line $LINENO"' ERR

[[ $EUID -eq 0 ]] || die "Must run as root. Try: sudo $0"

ALL_SVCS=(
  lab-api lab-worker lab-scheduler lab-logger
  lab-cpu-hog lab-memory-leak lab-permission-bug
  lab-network-api lab-network-wrong-port lab-network-loopback
  lab-network-firewalled lab-network-dns-client
)

log "Stopping + disabling all lab services"
for svc in "${ALL_SVCS[@]}"; do
  systemctl stop    "$svc" >/dev/null 2>&1 || true
  systemctl disable "$svc" >/dev/null 2>&1 || true
done

log "Removing systemd unit files"
for svc in "${ALL_SVCS[@]}"; do
  rm -f "/etc/systemd/system/${svc}.service"
done
systemctl daemon-reload
systemctl reset-failed >/dev/null 2>&1 || true

log "Cleaning up networking scenario artifacts"
iptables -D INPUT -p tcp --dport 9083 -j DROP 2>/dev/null || true
sed -i '/lab-network-api\.local/d' /etc/hosts 2>/dev/null || true

log "Removing $LAB_HOME and $LAB_LOG_DIR"
rm -rf "$LAB_HOME" "$LAB_LOG_DIR"

if id -u "$LAB_USER" >/dev/null 2>&1; then
  log "Removing user '$LAB_USER'"
  userdel "$LAB_USER" || true
fi

log "Uninstall complete."
