#!/usr/bin/env bash
#
# break-firewall.sh — Add an iptables DROP rule to block port 9083.
# Part of Scenario 5 (Networking Failure). Idempotent: safe to re-run.
# Requires root.
#
set -Eeuo pipefail

PORT=9083

if iptables -C INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null; then
  echo "[break-firewall] DROP rule for port $PORT already exists"
else
  iptables -A INPUT -p tcp --dport "$PORT" -j DROP
  echo "[break-firewall] Added DROP rule for port $PORT"
fi
