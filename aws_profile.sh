# List AWS CLI profiles from the config file.
function aws-config-profiles()
{
    local aws_config_file="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

    if [ ! -f "$aws_config_file" ]; then
        return 1
    fi

    awk -F '[][]' '
        /^\[default\]$/ { print "default" }
        /^\[profile[[:space:]]+[^]]+\]$/ {
            profile = $2
            sub(/^profile[[:space:]]+/, "", profile)
            print profile
        }
    ' "$aws_config_file"
}

# Select an AWS CLI profile from the config file using the default fuzzy finder.
function aws-config-profile-select()
{
    aws-config-profiles | default-fuzzy-finder
}

# aws-tool aws-profile-set: Set the AWS CLI profile to use.
function aws-profile-set () {
    local target_aws_profile="$1"
    if [ -z "$target_aws_profile" ]
    then
        target_aws_profile=$(aws-config-profile-select)
    fi

    if [ -z "$target_aws_profile" ]; then
        echo "No AWS profile selected"
        return 1
    fi

    export AWS_PROFILE="$target_aws_profile"
    echo "AWS profile set to $AWS_PROFILE"
    # set region
    region=$(aws configure get region --profile "$AWS_PROFILE")
}
alias aps="aws-profile-set"


# aws-tool aws-profile: Display the current AWS profile.
function aws-profile()
{
    echo "The current AWS profile is:"
    echo $AWS_PROFILE
}
alias ap="aws-profile"


# aws-tool aws-list-profiles: List all AWS CLI profiles from the config file.
function aws-list-profiles()
{
    aws-config-profiles
}
alias alp="aws-list-profiles"


# aws-tool aws-sso-login: Login to AWS SSO using a selected AWS CLI profile.
function aws-sso-login()
{
    local target_aws_profile="$1"
    if [ -z "$target_aws_profile" ]; then
        target_aws_profile=$(aws-config-profile-select)
    fi

    if [ -z "$target_aws_profile" ]; then
        echo "No AWS profile selected"
        return 1
    fi

    aws sso login --profile "$target_aws_profile"
}
alias asl="aws-sso-login"

# aws-tool aws-sts-get-caller-identity: Get caller identity using a selected AWS CLI profile.
function aws-sts-get-caller-identity()
{
    local target_aws_profile="$1"
    if [ -z "$target_aws_profile" ]; then
        target_aws_profile=$(aws-config-profile-select)
    fi

    if [ -z "$target_aws_profile" ]; then
        echo "No AWS profile selected"
        return 1
    fi

    aws sts get-caller-identity --profile "$target_aws_profile"
}
alias agci="aws-sts-get-caller-identity"
