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

if [[ "$STARTUP_SYNC" == 1 ]]; then
    /s3-sync.sh
fi

if [[ "$CRON_SYNC" == 1 ]]; then
    printenv >> /var/spool/cron/crontabs/root
    echo "$CRON_SCHEDULE /s3-sync.sh" >> /var/spool/cron/crontabs/root
    crond -l 2 -f
fi
