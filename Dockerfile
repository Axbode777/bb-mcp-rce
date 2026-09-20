FROM alpine:3.19
RUN apk add --no-cache python3
WORKDIR /app
EXPOSE 8080
CMD ["sh", "-c", "printf 'S14-MCP-RCE host=%s uid=%s\\n' \"$(hostname)\" \"$(id -u)\" > /app/index.html; exec python3 -m http.server 8080"]
