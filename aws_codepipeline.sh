
function aws-codepipeline-list-action-executions()
{
    PIPELINE=$1
    EXEC_ID=$2

    if [ -z "$PIPELINE" ]; then
        echo "Usage: aws-codepipeline-list-action-executions <PIPELINE> [EXEC_ID]"
        return 1
    fi

    if [ -z "$EXEC_ID" ]; then
        # Get all pipeline names and select one using fuzzy finder
        EXEC_ID=$(aws codepipeline list-pipeline-executions --pipeline-name "$PIPELINE" --query "pipelineExecutionSummaries[].pipelineExecutionId" --output json | jq -r '.[]' | default-fuzzy-finder)
    fi

    echo "Fetching action executions for pipeline '$PIPELINE' and execution ID '$EXEC_ID'..."

    RESULT=$(aws codepipeline list-action-executions \
      --pipeline-name "$PIPELINE" \
      --filter pipelineExecutionId="$EXEC_ID" \
      --query 'actionExecutionDetails[].{
        stage:stageName,
        action:actionName,
        status:status,
        start:startTime,
        end:lastUpdatedBy,
        summary:output.executionResult.summary,
        externalId:output.externalExecutionId,
        url:output.executionResult.externalExecutionUrl
      }' --output json)
    echo "$RESULT"
}

