#!/usr/bin/env bash
#
# api.sh — Minimal "API" service for the lab.
# Listens on TCP :8080 using bash + /dev/tcp via socat-free nc fallback isn't reliable,
# so we use a tiny Python one-liner. That's fine — Python 3 is on Ubuntu 24.04 by default.
#
set -Eeuo pipefail

LAB_LOG_DIR="${LAB_LOG_DIR:-/var/log/linux-ops-lab}"
LOG="$LAB_LOG_DIR/api.log"
PORT="${LAB_API_PORT:-8080}"
BODY="linux-ops-lab healthy"

trap 'echo "[api] received signal, exiting" | tee -a "$LOG"; exit 0' INT TERM

mkdir -p "$LAB_LOG_DIR"

log() {
  printf '%s [api] %s\n' "$(date --iso-8601=seconds)" "$*" | tee -a "$LOG"
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
        sys.stdout.write('%s [api] %s\n' % (datetime.datetime.now().isoformat(timespec='seconds'), fmt % args))
        sys.stdout.flush()
with socketserver.TCPServer(('0.0.0.0', ${PORT}), H) as httpd:
    httpd.serve_forever()
"
