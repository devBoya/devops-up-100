#!/usr/bin/env bash
#
# install.sh — Bootstrap the linux-ops-lab-week1 environment on Ubuntu 24.04 LTS.
#
# Idempotent: safe to re-run. Fails loudly on any error.
#
set -Eeuo pipefail

LAB_USER="labapp"
LAB_HOME="/opt/linux-ops-lab"
LAB_LOG_DIR="/var/log/linux-ops-lab"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;36m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install:warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[install:err]\033[0m %s\n' "$*" >&2; exit 1; }

trap 'die "install.sh failed at line $LINENO (command: $BASH_COMMAND)"' ERR

require_root() {
  if [[ $EUID -ne 0 ]]; then
    die "Must run as root. Try: sudo $0"
  fi
}

require_ubuntu_24_04() {
  if ! command -v lsb_release >/dev/null 2>&1; then
    warn "lsb_release missing — installing lsb-release"
    apt-get update -qq && apt-get install -y -qq lsb-release
  fi
  local id ver
  id="$(lsb_release -si)"
  ver="$(lsb_release -sr)"
  if [[ "$id" != "Ubuntu" || "$ver" != "24.04" ]]; then
    warn "Detected $id $ver — this lab targets Ubuntu 24.04 LTS. Continuing anyway."
  fi
}

ensure_user() {
  if id -u "$LAB_USER" >/dev/null 2>&1; then
    log "User '$LAB_USER' already exists"
  else
    log "Creating system user '$LAB_USER'"
    useradd --system --home-dir "$LAB_HOME" --shell /usr/sbin/nologin "$LAB_USER"
  fi
}

ensure_dirs() {
  log "Ensuring $LAB_HOME and $LAB_LOG_DIR exist"
  install -d -o "$LAB_USER" -g "$LAB_USER" -m 0755 "$LAB_HOME"
  install -d -o "$LAB_USER" -g "$LAB_USER" -m 0755 "$LAB_HOME/scripts"
  install -d -o "$LAB_USER" -g "$LAB_USER" -m 0755 "$LAB_LOG_DIR"
}

install_scripts() {
  log "Installing service scripts into $LAB_HOME/scripts"
  install -o "$LAB_USER" -g "$LAB_USER" -m 0755 \
    "$REPO_DIR"/scripts/*.sh "$LAB_HOME/scripts/"
}

install_units() {
  log "Installing systemd unit files"
  install -o root -g root -m 0644 \
    "$REPO_DIR"/systemd/*.service /etc/systemd/system/
  systemctl daemon-reload
}

start_healthy_services() {
  local healthy=(lab-api lab-worker lab-scheduler lab-logger)
  for svc in "${healthy[@]}"; do
    log "Enabling + starting $svc"
    systemctl enable --now "$svc"
  done
}

ensure_failure_services_disabled() {
  local broken=(lab-cpu-hog lab-memory-leak lab-permission-bug
                lab-network-api lab-network-wrong-port lab-network-loopback
                lab-network-firewalled lab-network-dns-client)
  for svc in "${broken[@]}"; do
    log "Disabling failure service $svc (off by default)"
    systemctl disable "$svc" >/dev/null 2>&1 || true
    systemctl stop "$svc"    >/dev/null 2>&1 || true
  done
}

install_packages() {
  log "Installing required packages (curl, jq, htop, procps)"
  DEBIAN_FRONTEND=noninteractive apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    curl jq htop procps net-tools sysstat \
    dnsutils tcpdump iptables
}

print_status() {
  log "--- Installed services status ---"
  systemctl --no-pager --full status \
    lab-api lab-worker lab-scheduler lab-logger 2>&1 \
    | sed 's/^/  /' || true
  log "Smoke test:"
  if curl -sf --max-time 3 localhost:8080 >/dev/null; then
    echo "  curl localhost:8080 → $(curl -s localhost:8080)"
  else
    warn "  curl localhost:8080 did not respond — give lab-api a few seconds, then re-check"
  fi
}

setup_dns_entry() {
  local hostname="lab-network-api.local"
  local marker="# linux-ops-lab"
  if ! grep -q "$hostname" /etc/hosts; then
    log "Adding $hostname to /etc/hosts"
    echo "127.0.0.1 $hostname $marker" >> /etc/hosts
  else
    log "$hostname already in /etc/hosts"
  fi
}

main() {
  require_root
  require_ubuntu_24_04
  install_packages
  ensure_user
  ensure_dirs
  install_scripts
  install_units
  setup_dns_entry
  ensure_failure_services_disabled
  start_healthy_services
  print_status
  log "Install complete. Run ./healthcheck.sh to see system state."
}

main "$@"
