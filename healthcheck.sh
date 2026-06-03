#!/usr/bin/env bash
#
# healthcheck.sh — Print a single-screen snapshot of system + lab health.
# Designed to be the canonical example of "useful Bash automation" for the lab.
#
set -Eeuo pipefail

LAB_LOG_DIR="/var/log/linux-ops-lab"
SERVICES=(lab-api lab-worker lab-scheduler lab-logger lab-cpu-hog lab-memory-leak lab-permission-bug)

bold()    { printf '\033[1m%s\033[0m\n' "$*"; }
section() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
kv()      { printf '  %-18s %s\n' "$1" "$2"; }

section "System"
kv "Hostname"        "$(hostname)"
kv "Kernel"          "$(uname -srm)"
kv "Distro"          "$(lsb_release -ds 2>/dev/null || echo 'unknown')"
kv "Uptime"          "$(uptime -p)"
kv "Load average"    "$(awk '{print $1, $2, $3}' /proc/loadavg)"

section "Memory"
free -h | sed 's/^/  /'

section "Disk"
df -hT --total -x tmpfs -x devtmpfs | sed 's/^/  /'

section "Lab services"
for svc in "${SERVICES[@]}"; do
  if systemctl list-unit-files "${svc}.service" >/dev/null 2>&1; then
    state="$(systemctl is-active "$svc" 2>/dev/null || echo unknown)"
    sub="$(systemctl is-enabled "$svc" 2>/dev/null || echo unknown)"
    printf '  %-22s active=%-10s enabled=%s\n' "$svc" "$state" "$sub"
  else
    printf '  %-22s (not installed)\n' "$svc"
  fi
done

section "Listening ports"
if command -v ss >/dev/null 2>&1; then
  ss -tulnp 2>/dev/null | sed 's/^/  /'
else
  netstat -tulnp 2>/dev/null | sed 's/^/  /' || echo "  (install iproute2 or net-tools)"
fi

section "Top 5 CPU processes"
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | sed 's/^/  /'

section "Top 5 memory processes"
ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 6 | sed 's/^/  /'

section "Recent lab log activity"
if [[ -d "$LAB_LOG_DIR" ]]; then
  ls -lh "$LAB_LOG_DIR" 2>/dev/null | sed 's/^/  /'
else
  echo "  $LAB_LOG_DIR does not exist yet — has install.sh been run?"
fi

echo
bold "healthcheck complete."
