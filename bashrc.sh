
source ${AWS_UTILS_DIR}/aws_profile.sh
source ${AWS_UTILS_DIR}/aws_cloudformation.sh
source ${AWS_UTILS_DIR}/aws_role.sh
source ${AWS_UTILS_DIR}/aws_codepipeline.sh
source ${AWS_UTILS_DIR}/aws_ssm.sh
source ${AWS_UTILS_DIR}/aws_cloudwatch.sh
source ${AWS_UTILS_DIR}/aws_s3.sh
source ${AWS_UTILS_DIR}/aws_ecr.sh
source ${AWS_UTILS_DIR}/aws_ecs.sh

function aws-fz()
{
    # droid_action=$(cat ${ANDROID_DEV_SCRIPTS_DIR}/dev/*android*.sh | grep '# droidtool' | cut -c12- | default-fuzzy-finder | tr ':' ' ' | awk '{print $1}')
    # eval ${droid_action}

    local aws_action=$(cat ${AWS_UTILS_DIR}/aws_*.sh | grep '# aws-tool' | cut -c11- | default-fuzzy-finder | tr ':' ' ' | awk '{print $1}')
    eval ${aws_action}
}
alias aw='aws-fz'
