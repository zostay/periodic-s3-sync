#/bin/ash

set -e

if [[ "$ROLE_ARN" -a -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo "Operating as $ROLE_ARN"

    session_info=$(aws sts assume-role \
        --role-arn $ROLE_ARN \
        --role-session-name periodic-s3-sync)

    if [[ "$DEBUG_SESSION_INFO" ]]; then
        echo $session_info
    fi

    export AWS_ACCESS_KEY_ID=$(echo $session_info | jq -r .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo $session_info | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo $session_info | jq -r .Credentials.SessionToken)
fi

echo "$(date) - Start Sync $SYNC_FROM -> $SYNC_TO"

aws s3 sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS

echo "$(date) - End Sync $SYNC_FROM -> $SYNC_TO"
