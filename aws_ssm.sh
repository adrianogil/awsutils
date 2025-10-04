
# Get the SSM parameter store value
function aws-ssm-parameter-get() {
  local parameter_name="$1"

  if [[ -z "$parameter_name" ]]; then
    echo "Usage: aws-ssm-parameter-get <parameter-name>"
    return 1
  fi

  aws ssm get-parameter --name "$parameter_name" --query 'Parameter.Value' --output text
}
