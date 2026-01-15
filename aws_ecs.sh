
# aws-tool aws-ecs-debug: Select an ECS cluster/task/container with fuzzy finder and open a shell via execute-command.
function aws-ecs-debug() {
    local cluster_name="$1"
    local task_arn="$2"
    local container_name="$3"

    if [[ -z "$cluster_name" ]]; then
        echo "Selecting ECS cluster..."
        cluster_name=$(aws ecs list-clusters --query "clusterArns[]" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$cluster_name" ]]; then
        echo "Usage: aws-ecs-debug <cluster-arn|cluster-name> [task-arn] [container-name]"
        return 1
    fi

    if [[ -z "$task_arn" ]]; then
        echo "Fetching tasks for cluster: $cluster_name"
        local -a task_arns
        task_arns=()
        while IFS= read -r task_arn_line; do
            [[ -n "$task_arn_line" ]] && task_arns+=("$task_arn_line")
        done < <(aws ecs list-tasks --cluster "$cluster_name" --query "taskArns[]" --output json | jq -r '.[]')

        if [[ "${#task_arns[@]}" -eq 0 ]]; then
            echo "No running tasks found in cluster: $cluster_name"
            return 1
        fi

        echo "Selecting task (showing task definition name)..."
        task_arn=$(aws ecs describe-tasks --cluster "$cluster_name" --tasks "${task_arns[@]}" --output json \
            | jq -r '.tasks[] | .taskDefinitionArn as $task_def | "\($task_def | split("/")[-1])\t\(.taskArn)"' \
            | default-fuzzy-finder \
            | cut -f2)
    fi

    if [[ -z "$task_arn" ]]; then
        echo "No task selected."
        return 1
    fi

    if [[ -z "$container_name" ]]; then
        echo "Selecting container for task: $task_arn"
        container_name=$(aws ecs describe-tasks --cluster "$cluster_name" --tasks "$task_arn" --query "tasks[0].containers[].name" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    if [[ -z "$container_name" ]]; then
        echo "No container selected."
        return 1
    fi

    echo "Starting ECS execute-command..."
    aws ecs execute-command \
        --cluster "$cluster_name" \
        --task "$task_arn" \
        --container "$container_name" \
        --interactive \
        --command "/bin/sh"
}
