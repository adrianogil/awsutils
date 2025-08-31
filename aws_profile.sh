function aws-profile-set () {
    target_aws_profile=$1
    if [ -z "$target_aws_profile" ]
    then
        # Use awk to extract profiles from ~/.aws/credentials
        target_aws_profile=$(awk -F '[][]' '/\[.*\]/ {print $2}' ~/.aws/credentials | default-fuzzy-finder)
    fi
    export AWS_PROFILE=$target_aws_profile
    echo "AWS profile set to $AWS_PROFILE"
    # set region
    region=$(aws configure get region --profile $AWS_PROFILE)
}
alias aps="aws-profile-set"

function aws-profile()
{
    echo "The current AWS profile is:"
    echo $AWS_PROFILE
}
alias ap="aws-profile"

function aws-list-profiles()
{
    awk -F '[][]' '/\[.*\]/ {print $2}' ~/.aws/credentials
}
alias alp="aws-list-profiles"

