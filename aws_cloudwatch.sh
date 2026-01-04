
function aws-cloudwatch-log-group-tail() {
  local log_group_name="$1"
  shift || true

  if [[ -z "$log_group_name" ]]; then
    log_group_name=$(aws logs describe-log-groups --query "logGroups[].logGroupName" --output json | jq -r '.[]' | default-fuzzy-finder)
  fi

  if [[ -z "$log_group_name" ]]; then
    echo "Usage: aws-cloudwatch-log-group-tail <log-group-name> [aws logs tail options]"
    return 1
  fi

  aws logs tail "$log_group_name" --follow "$@"
}
