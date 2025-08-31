function aws-role-get-info()
{
    ROLE_NAME=$1

    if [ -z "$ROLE_NAME" ]; then
        echo "Usage: aws-role-get-info <ROLE_NAME>"
        return 1
    fi

    echo "Fetching info for role '$ROLE_NAME'..."

    RESULT=$(aws iam get-role --role-name "$ROLE_NAME" --output json)
    echo "$RESULT"
}