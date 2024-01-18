data "aws_organizations_organization" "gds" {}


data "aws_cloudformation_stack" "aws-signer" {
  name = "aws-signer"
}

module "codebuild-image-ecr" {
  source     = "git@github.com:govuk-one-login/ipv-terraform-modules.git//secure-pipeline/container-image-repository"
  stack_name = "codebuild-image-ecr"
  parameters = {
    PipelineStackName = "codebuild-image-pipeline"
    #AWSOrganizationId = data.aws_organizations_organization.gds.id
  }

  tags_custom = {
    System = "DevPlatform"
  }

  depends_on = [
    module.codebuild-image-pipeline
  ]
}

module "codebuild-image-pipeline" {
  source     = "git@github.com:govuk-one-login/ipv-terraform-modules//secure-pipeline/deploy-pipeline"
  template_url = "https://template-storage-templatebucket-1upzyw6v9cs42.s3.eu-west-2.amazonaws.com/sam-deploy-pipeline/template.yaml"
  stack_name = "codebuild-image-pipeline"
  parameters = {
    SAMStackName               = "codebuild-image"
    Environment                = "build"
    VpcStackName               = "none"
    IncludePromotion           = "No"
    # AWSOrganizationId          = data.aws_organizations_organization.gds.id
    LogRetentionDays           = 7
    SigningProfileArn          = data.aws_cloudformation_stack.aws-signer.outputs["SigningProfileArn"]
    SigningProfileVersionArn   = data.aws_cloudformation_stack.aws-signer.outputs["SigningProfileVersionArn"]
    OneLoginRepositoryName     = "devplatform-build-image"
    SlackNotificationType      = "Failures"
    BuildNotificationStackName = "build-notifications"
  }

  tags_custom = {
    System = "DevPlatform"
  }
}