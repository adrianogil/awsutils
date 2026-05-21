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


# aws-tool aws-profile-rename: Rename an AWS CLI profile in config and credentials files.
function aws-profile-rename()
{
    local source_profile="$1"
    local target_profile="$2"
    local aws_config_file="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
    local aws_credentials_file="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"

    if [ -z "$source_profile" ]; then
        source_profile=$(aws-config-profile-select)
    fi

    if [ -z "$source_profile" ]; then
        echo "No AWS profile selected"
        return 1
    fi

    if [ -z "$target_profile" ]; then
        read -r -p "Enter the new profile name: " target_profile
    fi

    if [ -z "$target_profile" ]; then
        echo "No new profile name provided"
        return 1
    fi

    if [ "$source_profile" = "$target_profile" ]; then
        echo "Source and target profile names are the same"
        return 1
    fi

    if ! aws-config-profiles | grep -Fxq "$source_profile"; then
        echo "Profile '$source_profile' not found in config"
        return 1
    fi

    if aws-config-profiles | grep -Fxq "$target_profile"; then
        echo "Profile '$target_profile' already exists in config"
        return 1
    fi

    if [ -f "$aws_config_file" ]; then
        awk -v source="$source_profile" -v target="$target_profile" '
            $0 == "[profile " source "]" {
                print "[profile " target "]"
                next
            }
            source == "default" && $0 == "[default]" {
                print "[profile " target "]"
                next
            }
            {
                print
            }
        ' "$aws_config_file" > "${aws_config_file}.tmp" && mv "${aws_config_file}.tmp" "$aws_config_file"
    fi

    if [ -f "$aws_credentials_file" ]; then
        if grep -Fxq "[$target_profile]" "$aws_credentials_file"; then
            echo "Profile '$target_profile' already exists in credentials"
            return 1
        fi

        awk -v source="$source_profile" -v target="$target_profile" '
            $0 == "[" source "]" {
                print "[" target "]"
                next
            }
            {
                print
            }
        ' "$aws_credentials_file" > "${aws_credentials_file}.tmp" && mv "${aws_credentials_file}.tmp" "$aws_credentials_file"
    fi

    if [ "$AWS_PROFILE" = "$source_profile" ]; then
        export AWS_PROFILE="$target_profile"
    fi

    echo "Renamed profile '$source_profile' to '$target_profile'"
}
alias apr="aws-profile-rename"
