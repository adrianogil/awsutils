
# aws-tool aws-cloudwatch-log-group-tail: Tail logs from a CloudWatch log group with optional filtering and follow mode.
function aws-cloudwatch-log-group-tail() {
    local log_group_name="$1"
    [[ $# -gt 0 ]] && shift

    if [[ -z "$log_group_name" ]]; then
        log_group_name=$(aws logs describe-log-groups --query "logGroups[].logGroupName" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$log_group_name" ]]; then
        echo "Usage: aws-cloudwatch-log-group-tail <log-group-name> [aws logs tail options]"
        return 1
    fi

    echo "Tailing logs from log group: $log_group_name"
    aws logs tail "$log_group_name" --follow "$@"
}

# aws-tool aws-cloudwatch-log-group: Select a CloudWatch log group and stream, then show its events.
function aws-cloudwatch-log-group() {
    local log_group_name="$1"
    local log_stream_name="$2"
    if [[ $# -ge 2 ]]; then
        shift 2
    elif [[ $# -eq 1 ]]; then
        shift
    fi

    if [[ -z "$log_group_name" ]]; then
        log_group_name=$(aws logs describe-log-groups --query "logGroups[].logGroupName" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$log_group_name" ]]; then
        echo "Usage: aws-cloudwatch-log-group <log-group-name> <log-stream-name> [aws logs get-log-events options]"
        return 1
    fi

    if [[ -z "$log_stream_name" ]]; then
        log_stream_name=$(aws logs describe-log-streams --log-group-name "$log_group_name" --order-by LastEventTime --descending --max-items 20 --query "logStreams[].logStreamName" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$log_stream_name" ]]; then
        echo "Usage: aws-cloudwatch-log-group <log-group-name> <log-stream-name> [aws logs get-log-events options]"
        return 1
    fi

    echo "Showing log events from log group: $log_group_name"
    echo "Log stream: $log_stream_name"
    aws logs get-log-events --log-group-name "$log_group_name" --log-stream-name "$log_stream_name" "$@"
}
