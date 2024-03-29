#!/bin/ash

set -e

echo "$(date) - Start Sync $SYNC_FROM -> $SYNC_TO"

aws s3 sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS

if [[ -n "$CHOWN_OWNER" ]] && [[ "$SYNC_TO" != "s3:"* ]]; then
    echo CHOWN $CHOWN_OWNER
    chown -R "$CHOWN_OWNER" "$SYNC_TO"
fi

if [[ -n "$CHMOD_MODE" ]] && [[ "$SYNC_TO" != "s3:"* ]]; then
    echo CHMOD $CHMOD_MODE
    chmod -R "$CHMOD_MODE" "$SYNC_TO"
fi

# touch the completion file somewhere locally if requested on completion, but
# only do this during the startup sync.
if [[ "$__STARTUP_SYNC_IN_PROGRESS" && "$COMPLETION_FILENAME" ]]; then
    if [[ "$SYNC_TO" != "s3:"* ]]; then
        touch "$SYNC_TO/$COMPLETION_FILENAME"
        chmod a+r "$SYNC_TO/$COMPLETION_FILENAME"
        echo $(date) TOUCH $SYNC_TO/$COMPLETION_FILENAME
    fi
    if [[ "$SYNC_FROM" != "s3:"* ]]; then
        touch "$SYNC_FROM/$COMPLETION_FILENAME"
        chmod a+r "$SYNC_FROM/$COMPLETION_FILENAME"
        echo $(date) TOUCH $SYNC_FROM/$COMPLETION_FILENAME
    fi
fi

echo "$(date) - End Sync $SYNC_FROM -> $SYNC_TO"
