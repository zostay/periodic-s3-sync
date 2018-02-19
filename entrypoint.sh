#!/bin/ash

set -e

case $SYNC_MODE in
    STARTUP|STARTUP+*|*+STARTUP|*+STARTUP+*) STARTUP_SYNC=1 ;;
    *)                                       STARTUP_SYNC=0 ;;
esac

case $SYNC_MODE in
    PERIODIC|PERIODIC+*|*+PERIODIC|*+PERIODIC+*) CRON_SYNC=1 ;;
    *)                                           CRON_SYNC=0 ;;
esac

AWS_ENV="
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_SESSION_TOKEN
    AWS_DEFAULT_REGION
    AWS_DEFAULT_OUTPUT
    AWS_PROFILE
    AWS_CA_BUNDLE
    AWS_SHARED_CREDENTIALS_FILE
    AWS_CONFIG_FILE
"

for var in $AWS_ENV; do
    eval value=\$$var
    #echo "$var=$value"
    if [[ -z "$value" ]]; then
        unset $var
    else
        export $var
    fi
done

if [[ "$STARTUP_SYNC" == 1 ]]; then
    /s3-sync.sh
fi

if [[ "$CRON_SYNC" == 1 ]]; then
    echo "$CRON_SCHEDULE /s3-sync.sh" >> /var/spool/cron/crontabs/root
    crond -l 2 -f
fi
