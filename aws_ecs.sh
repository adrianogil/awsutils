
# aws-tool aws-ecs-debug: Select an ECS cluster/task/container with fuzzy finder and open a shell via execute-command.
function aws-ecs-debug() {
    local cluster_name="$1"
    local task_arn="$2"
    local container_name="$3"

    if [[ -z "$cluster_name" ]]; then
        cluster_name=$(aws ecs list-clusters --query "clusterArns[]" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$cluster_name" ]]; then
        echo "Usage: aws-ecs-debug <cluster-arn|cluster-name> [task-arn] [container-name]"
        return 1
    fi

    if [[ -z "$task_arn" ]]; then
        local task_arns
        task_arns=$(aws ecs list-tasks --cluster "$cluster_name" --query "taskArns[]" --output json | jq -r '.[]')

        if [[ -z "$task_arns" ]]; then
            echo "No running tasks found in cluster: $cluster_name"
            return 1
        fi

        task_arn=$(aws ecs describe-tasks --cluster "$cluster_name" --tasks $task_arns --output json \
            | jq -r '.tasks[] | .taskDefinitionArn as $def | "\($def | split("/")[-1])\t\(.taskArn)"' \
            | default-fuzzy-finder \
            | cut -f2)
    fi

    if [[ -z "$task_arn" ]]; then
        echo "No task selected."
        return 1
    fi

    if [[ -z "$container_name" ]]; then
        container_name=$(aws ecs describe-tasks --cluster "$cluster_name" --tasks "$task_arn" --query "tasks[0].containers[].name" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$container_name" ]]; then
        echo "No container selected."
        return 1
    fi

    aws ecs execute-command \
        --cluster "$cluster_name" \
        --task "$task_arn" \
        --container "$container_name" \
        --interactive \
        --command "/bin/sh"
}
