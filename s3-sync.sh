#!/bin/ash

set -e

echo "$(date) - Start Sync $SYNC_FROM -> $SYNC_TO"

aws s3 sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS

# touch the completion file somewhere locally if requested on completion, but
# only do this during the startup sync.
if [[ -n "$__STARTUP_SYNC_IN_PROGRESS" && -n "$COMPLETION_FILENAME" ]]; then
    if [[ "$SYNC_TO" != "s3:"* ]]; then
        touch $SYNC_TO/
    fi
    if [[ "$SYNC_FROM" != "s3:"* ]]; then
        touch $SYNC_FROM/
    fi
fi

echo "$(date) - End Sync $SYNC_FROM -> $SYNC_TO"
