
# aws-tool aws-ecr-images: Select an ECR repository with fuzzy finder and list its images.
function aws-ecr-images() {
    local repository_name="$1"
    if [[ $# -gt 0 ]]; then
        shift
    fi

    if [[ -z "$repository_name" ]]; then
        repository_name=$(aws ecr describe-repositories --query "repositories[].repositoryName" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$repository_name" ]]; then
        echo "Usage: aws-ecr-images <repository-name> [aws ecr describe-images options]"
        return 1
    fi

    echo "Listing images for repository: $repository_name"
    aws ecr describe-images \
        --repository-name "$repository_name" \
        --query 'imageDetails[].{tag: join(`,`, imageTags || [`<none>`]), digest: imageDigest, pushedAt: imagePushedAt, size: imageSizeInBytes}' \
        --output table \
        "$@"
}
