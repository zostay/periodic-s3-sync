#!/bin/ash

set -e

echo Parameters:
echo "  SYNC_FROM: $SYNC_FROM"
echo "  SYNC_TO: $SYNC_TO"
echo "  SYNC_PARAMS: $SYNC_PARAMS"
echo "  CHOWN_OWNER: $CHOWN_OWNER"
echo "  CHMOD_MODE: $CHMOD_MODE"
echo "  COMPLETION_FILENAME: $COMPLETION_FILENAME"
echo "  AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:+set}"
echo "  AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:+set}"
echo "  AWS_ENDPOINT_URL: ${AWS_ENDPOINT_URL:-default}"

# Build s3cmd endpoint flags for non-AWS S3-compatible stores
S3CMD_ENDPOINT_FLAGS=""
if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then
    # Extract hostname from URL (remove protocol prefix if present)
    S3_HOST=$(echo "$AWS_ENDPOINT_URL" | sed 's|^https\?://||' | sed 's|/.*$||')
    S3CMD_ENDPOINT_FLAGS="--host=$S3_HOST --host-bucket=%(bucket)s.$S3_HOST"
fi

echo "$(date) - Start Sync $SYNC_FROM -> $SYNC_TO"

s3cmd sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS $S3CMD_ENDPOINT_FLAGS

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
