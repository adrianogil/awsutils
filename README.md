# awsutils

Shell helpers for the AWS CLI. Load `bashrc.sh` with `AWS_UTILS_DIR` set to
this repository, or source `aws_cloudformation.sh` directly for the commands below.

## Export CloudFormation stacks

```sh
source /path/to/awsutils/aws_cloudformation.sh

# Save to cloudformation-stacks.json in the current directory.
aws-cloudformation-download-stacks

# Choose a destination, profile, and region.
aws-cloudformation-download-stacks stacks.json --profile production --region us-east-1
```

Requires an installed, authenticated AWS CLI and `cloudformation:ListStacks`
and `cloudformation:DescribeStacks` permissions. The command uses your configured
account/profile and region unless overridden. It retrieves **all pages in that
region**, including nested stacks; it does not scan other regions or accounts.
The command is also available through the `aws-fz` / `aw` menu.

The file contains a JSON array (or `[]` when there are no stacks):

```json
[
  {
    "Name": "my-app",
    "Id": "arn:aws:cloudformation:us-east-1:123456789012:stack/my-app/example-id",
    "Status": "UPDATE_COMPLETE",
    "Created": "2026-09-01T10:00:00+00:00",
    "LastUpdated": "2026-10-20T12:30:00+00:00",
    "DeployedAt": "2026-10-20T12:30:00+00:00",
    "Tags": [{"Key": "Environment", "Value": "production"}]
  }
]
```

`DeployedAt` uses `LastUpdatedTime`, falling back to `CreationTime` for stacks
that have never been updated (`LastUpdated` is then `null`). These are AWS's
stack timestamps, **not a guarantee of successful deployment completion**.
`Status` is included to distinguish failed, rolled-back, and in-progress stacks.
All current stacks returned by `describe-stacks` are included; this is not a
history of deleted stacks or deployments. `Tags` contains stack-level key/value
pairs, or `[]` for an untagged stack.

See the [AWS describe-stacks reference](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/describe-stacks.html)
for pagination and timestamp semantics.

The destination's parent directory must exist. A successful export replaces an
existing file; a failed AWS request leaves that file intact and returns a nonzero
exit status. No AWS resources are modified.

Run the offline command checks with `python3 -m unittest discover -s tests -v`.
