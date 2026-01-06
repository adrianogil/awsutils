
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
