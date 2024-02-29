FROM alpine:3.19.1

RUN apk --no-cache add \
        python3 \
        py3-pip \
        jq \
        ca-certificates \
        aws-cli

RUN aws --version

ENV AWS_CA_BUNDLE="/etc/ssl/cert.pem" \
    CRON_SCHEDULE="0 * * * *" \
    SYNC_MODE="STARTUP+PERIODIC" \
    SYNC_FROM="/data" \
    SYNC_TO="/data"

VOLUME /data

COPY s3-sync.sh /s3-sync.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
