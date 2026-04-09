# S3 bucket management functions for AWS CLI.


# aws-tool aws-s3-bucket-download: Download an S3 bucket locally (choose with fuzzy finder when omitted).
function aws-s3-bucket-download() {
    local bucket_name="$1"
    local destination_dir="$2"

    if [[ $# -gt 0 ]]; then
        shift
    fi
    if [[ $# -gt 0 ]]; then
        shift
    fi

    if [[ -z "$bucket_name" ]]; then
        bucket_name=$(aws s3api list-buckets --query 'Buckets[].Name' --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$bucket_name" ]]; then
        echo "Usage: aws-s3-bucket-download <bucket-name> [destination-dir] [aws s3 sync options]"
        return 1
    fi

    if [[ -z "$destination_dir" ]]; then
        destination_dir="./$bucket_name"
    fi

    echo "Downloading s3://$bucket_name to $destination_dir"
    aws s3 sync "s3://$bucket_name" "$destination_dir" "$@"
}
