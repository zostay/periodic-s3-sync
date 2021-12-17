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

if [[ -n "$COMPLETION_FILENAME" ]]; then
    SYNC_PARAMS="$SYNC_PARAMS --exclude $COMPLETION_FILENAME"
fi

if [[ "$STARTUP_SYNC" == 1 ]]; then
    __STARTUP_SYNC_IN_PROGRESS=1 /s3-sync.sh
fi

if [[ "$CRON_SYNC" == 1 ]]; then
    printenv >> /var/spool/cron/crontabs/root
    echo "$CRON_SCHEDULE /s3-sync.sh" >> /var/spool/cron/crontabs/root
    crond -l 2 -f
fi
