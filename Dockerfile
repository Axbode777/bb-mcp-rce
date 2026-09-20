FROM alpine:3.19
RUN apk add --no-cache python3 curl
WORKDIR /app
EXPOSE 8080
COPY out.sh /app/out.sh
CMD ["/bin/sh","/app/out.sh"]
