#!/usr/bin/env bash
#
# fix-firewall.sh — Remove iptables DROP rules blocking port 9083.
# Part of Scenario 5 (Networking Failure). Idempotent: safe to re-run.
# Requires root.
#
set -Eeuo pipefail

PORT=9083

while iptables -C INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null; do
  iptables -D INPUT -p tcp --dport "$PORT" -j DROP
  echo "[fix-firewall] Removed DROP rule for port $PORT"
done

echo "[fix-firewall] No DROP rules for port $PORT remain"
