#!/usr/bin/env bash
#
# network-loopback.sh — Scenario 5: service bound to localhost only.
# Listens on 127.0.0.1:9082 instead of 0.0.0.0:9082.
# Reachable inside the VM but not from the host or other machines.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/network-loopback.log"
PORT="${LAB_NETWORK_LOOPBACK_PORT:-9082}"
# BUG: binds to 127.0.0.1 instead of 0.0.0.0
BIND="127.0.0.1"
BODY="lab-network-loopback — bound to localhost only"

trap 'echo "[network-loopback] received signal, exiting" | tee -a "$LOG"; exit 0' INT TERM

mkdir -p "$LAB_LOG_DIR"

log() {
  printf '%s [network-loopback] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG"
}

heartbeat() {
  while true; do
    log "heartbeat ok"
    sleep 15
  done
}

heartbeat &
HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT

log "starting HTTP server on $BIND:$PORT"

exec python3 -u -c "
import http.server, socketserver, datetime, sys
BODY = b'${BODY}\n'
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.send_header('Content-Length', str(len(BODY)))
        self.end_headers()
        self.wfile.write(BODY)
    def log_message(self, fmt, *args):
        sys.stdout.write('%s [network-loopback] %s\n' % (datetime.datetime.now().isoformat(timespec='seconds'), fmt % args))
        sys.stdout.flush()
with socketserver.TCPServer(('${BIND}', ${PORT}), H) as httpd:
    httpd.serve_forever()
"
