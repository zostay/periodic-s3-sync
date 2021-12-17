#!/bin/ash

set -e

echo "$(date) - Start Sync $SYNC_FROM -> $SYNC_TO"

aws s3 sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS

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
