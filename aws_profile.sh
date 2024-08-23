function aws-profile-set()
{
    target_aws_profile=$1
    if [ -z $target_aws_profile ]; then
        # Get aws profile from ~/.aws/credentials using fuzzy search
        target_aws_profile=$(cat ~/.aws/credentials | grep -oP '\[.*\]' | tr -d '[]' | default-fuzzy-finder)
    fi
    export AWS_PROFILE=$target_aws_profile
    echo $AWS_PROFILE
}
alias aps="aws-profile-set"

function aws-profile()
{
    echo "The current AWS profile is:"
    echo $AWS_PROFILE
}
alias ap="aws-profile"
