#!/usr/bin/env bash
#
# network-api.sh — Healthy network API for Scenario 5 (Networking Failure).
# Listens on 0.0.0.0:9080. This is the reference service that should always work.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/network-api.log"
PORT="${LAB_NETWORK_API_PORT:-9080}"
BODY="lab-network-api healthy"

trap 'echo "[network-api] received signal, exiting" | tee -a "$LOG"; exit 0' INT TERM

mkdir -p "$LAB_LOG_DIR"

log() {
  printf '%s [network-api] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG"
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

log "starting HTTP server on :$PORT"

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
        sys.stdout.write('%s [network-api] %s\n' % (datetime.datetime.now().isoformat(timespec='seconds'), fmt % args))
        sys.stdout.flush()
with socketserver.TCPServer(('0.0.0.0', ${PORT}), H) as httpd:
    httpd.serve_forever()
"
