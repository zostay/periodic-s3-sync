FROM alpine:latest

RUN apk --no-cache add \
        python3 \
        py3-pip3 \
        jq \
        ca-certificates \
    && pip3 install --upgrade \
        pip \
        awscli

RUN aws --version

ENV ROLE_ARN= \
    SYNC_FROM= \
    SYNC_TO= \
    AWS_CA_BUNDLE="/etc/ssl/cert.pem" \
    CRON_SCHEDULE="0 * * * *" \
    SYNC_MODE="STARTUP+PERIODIC" \
    SYNC_PARAMS= \
    DEBUG_SESSION_INFO= \
    AWS_ACCESS_KEY_ID= \
    AWS_SECRET_ACCESS_KEY= \
    AWS_SESSION_TOKEN= \
    AWS_DEFAULT_REGION= \
    AWS_DEFAULT_OUTPUT= \
    AWS_PROFILE= \
    AWS_SHARED_CREDENTIALS_FILE= \
    AWS_CONFIG_FILE=

VOLUME /data

COPY s3-sync.sh /s3-sync.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
