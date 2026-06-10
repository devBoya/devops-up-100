#!/usr/bin/env bash
#
# fix-dns.sh — Restore DNS resolution for lab-network-api.local.
# Points the hostname back to 127.0.0.1.
# Part of Scenario 5 (Networking Failure). Idempotent: safe to re-run.
# Requires root.
#
set -Eeuo pipefail

HOSTS_FILE="/etc/hosts"
HOSTNAME="lab-network-api.local"
MARKER="# linux-ops-lab"

# Remove all existing entries for this hostname (correct or broken)
sed -i "/${HOSTNAME}/d" "$HOSTS_FILE"

# Add correct entry
echo "127.0.0.1 ${HOSTNAME} ${MARKER}" >> "$HOSTS_FILE"
echo "[fix-dns] Pointed ${HOSTNAME} to 127.0.0.1"
