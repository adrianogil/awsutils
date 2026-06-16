# AWS Secrets Manager helper functions.


# aws-tool aws-secretsmanager-secret-search: Search Secrets Manager secrets by name or another searchable field.
function aws-secretsmanager-secret-search() {
    local search_term="$1"
    local filter_key="name"

    if [[ -z "$search_term" ]]; then
        echo "Usage: aws-secretsmanager-secret-search <search-term> [name|description|tag-key|tag-value|primary-region|owning-service|all] [aws secretsmanager list-secrets options]"
        return 1
    fi

    shift

    if [[ $# -gt 0 ]]; then
        case "$1" in
            name|description|tag-key|tag-value|primary-region|owning-service|all)
                filter_key="$1"
                shift
                ;;
        esac
    fi

    echo "Searching Secrets Manager secrets where $filter_key contains: $search_term"
    aws secretsmanager list-secrets \
        --filters "Key=$filter_key,Values=$search_term" \
        --query 'SecretList[].{Name:Name,ARN:ARN,Description:Description,LastChangedDate:LastChangedDate,LastAccessedDate:LastAccessedDate}' \
        --output table \
        "$@"
}
alias ass="aws-secretsmanager-secret-search"
