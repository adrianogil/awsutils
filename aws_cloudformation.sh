
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

# aws-tool aws-cloudformation-list-stacks: List all CloudFormation stack names.
function aws-cloudformation-list-stacks() {
    aws cloudformation describe-stacks \
        --query "Stacks[].{Name:StackName,Status:StackStatus,LastUpdated:LastUpdatedTime,Created:CreationTime}" \
        --output table
}

# aws-tool aws-cloudformation-download-stacks: Save all current CloudFormation stacks, timestamps, and tags as JSON.
function aws-cloudformation-download-stacks() {
    local output_file="cloudformation-stacks.json"
    local temporary_file
    local aws_result
    local -a aws_options=()

    if [[ $# -gt 0 && "$1" != -* ]]; then
        output_file="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile|--region)
                if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
                    echo "Missing value for $1" >&2
                    return 1
                fi
                aws_options+=("$1" "$2")
                shift 2
                ;;
            --help|-h)
                echo "Usage: aws-cloudformation-download-stacks [output.json] [--profile NAME] [--region REGION]"
                return 0
                ;;
            *)
                echo "Unknown option: $1 (use --help for usage)" >&2
                return 1
                ;;
        esac
    done

    if [[ -z "$output_file" || -d "$output_file" ]]; then
        echo "Output must be a JSON file path, not a directory." >&2
        return 1
    fi

    # Write beside the destination so a failed request preserves an existing export.
    temporary_file=$(mktemp "${output_file}.tmp.XXXXXX") || return 1
    # The CLI automatically retrieves all pages; do not limit or disable pagination.
    if AWS_PAGER="" AWS_CLI_AUTO_PROMPT=off aws cloudformation describe-stacks \
        "${aws_options[@]}" \
        --query 'Stacks[].{Name:StackName,Id:StackId,Status:StackStatus,Created:CreationTime,LastUpdated:LastUpdatedTime,DeployedAt:not_null(LastUpdatedTime,CreationTime),Tags:not_null(Tags,`[]`)}' \
        --output json > "$temporary_file"; then
        if mv -f -- "$temporary_file" "$output_file"; then
            printf 'Saved CloudFormation stacks to %s\n' "$output_file"
        else
            rm -f -- "$temporary_file"
            return 1
        fi
    else
        aws_result=$?
        rm -f -- "$temporary_file"
        return "$aws_result"
    fi
}
