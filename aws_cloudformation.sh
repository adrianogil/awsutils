
function aws-cloudformation-describe-stack-get-resource-info() {
    RESOURCE_LOGICAL_ID=$1
    STACK_NAME=$2

    if [ -z "$RESOURCE_LOGICAL_ID" ]; then
        echo "Usage: aws-cloudformation-describe-stack-resource <RESOURCE_LOGICAL_ID> [STACK_NAME]"
        return 1
    fi

    if [ -z "$STACK_NAME" ]; then
        # Get all stack names and select one using fuzzy finder
        STACK_NAME=$(aws cloudformation describe-stacks --query "Stacks[].StackName" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    echo "Fetching resource info for LogicalResourceId '$RESOURCE_LOGICAL_ID' in stack '$STACK_NAME'..."

    RESULT=$(aws cloudformation describe-stack-resources \
      --stack-name "$STACK_NAME" \
      --query "StackResources[?LogicalResourceId=='$RESOURCE_LOGICAL_ID']" --output json)
    echo "$RESULT"
}
