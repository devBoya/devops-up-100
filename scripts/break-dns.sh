#!/usr/bin/env bash
#
# break-dns.sh — Break DNS resolution for lab-network-api.local.
# Points the hostname to 192.0.2.1 (RFC 5737 TEST-NET-1, non-routable).
# Part of Scenario 5 (Networking Failure). Idempotent: safe to re-run.
# Requires root.
#
set -Eeuo pipefail

HOSTS_FILE="/etc/hosts"
HOSTNAME="lab-network-api.local"
MARKER="# linux-ops-lab"

# Remove all existing entries for this hostname (correct or broken)
sed -i "/${HOSTNAME}/d" "$HOSTS_FILE"

# Add wrong entry — 192.0.2.1 is guaranteed non-routable (RFC 5737)
echo "192.0.2.1 ${HOSTNAME} ${MARKER}" >> "$HOSTS_FILE"
echo "[break-dns] Pointed ${HOSTNAME} to 192.0.2.1"
