# Container Image Repository
## Description
Creates ECR repositories for application images. This is required to deploy a container to Fargate with secure pipelines. This template requires that the CKV_AWS_32 Checkov check is disabled for the ContainerRepository resource. For more information, please visit the [documentation page][1].

### Parameters
The list of parameters for this template:

| Parameter        | Type   | Default   | Description |
|------------------|--------|-----------|-------------|
| AWSOrganizationId | CommaDelimitedList | o-pjzf8d99ys,o-dpp53lco28 | Comma-separated IDs of AWS Organizations where this account and the target pipeline account are members. |
| PipelineStackName | String |  | The name of SAM deploy pipeline stack which connects to GitHub Actions. This exports the IAM role that GitHub Actions assumes. |


### Resources
The list of resources this template creates:

| Resource         | Type   |
|------------------|--------|
| ContainerRepository | AWS::ECR::Repository |
| ContainerRepositoryPolicy | AWS::IAM::ManagedPolicy |


### Outputs
The list of outputs this template exposes:

| Output           | Description   |
|------------------|---------------|
| ContainerRepositoryName | The name of the ECR repository to push an image to. |
| ContainerRepositoryUri | The URI of the ECR repository to push an image to. |


[1]: https://govukverify.atlassian.net/wiki/spaces/PLAT/pages/3107258369/How+to+deploy+a+container+to+Fargate+with+secure+pipelines#Step-3%3A-Create-a-repository-in-ECR