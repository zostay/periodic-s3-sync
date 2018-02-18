#/bin/ash

set -e

echo "$(date) - Start Sync $SYNC_FROM -> $SYNC_TO"

aws s3 sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS

echo "$(date) - End Sync $SYNC_FROM -> $SYNC_TO"
