data "aws_organizations_organization" "gds" {}


data "aws_cloudformation_stack" "aws-signer" {
  name = "aws-signer"
}

module "codebuild-image-ecr" {
  source     = "../../../modules/codebuild-image-repository"
  stack_name = "codebuild-image-ecr"
  parameters = {
    GitHubRoleStackName = "codebuild-github-role"
    #AWSOrganizationId = data.aws_organizations_organization.gds.id
  }

  tags_custom = {
    System = "DevPlatform"
  }

  depends_on = [
    module.codebuild-github-role
  ]
}

module "codebuild-promotion-image-ecr" {
  source     = "../../../modules/codebuild-image-repository"
  stack_name = "codebuild-promotion-image-ecr"
  parameters = {
    GitHubRoleStackName = "codebuild-github-role"
    #AWSOrganizationId = data.aws_organizations_organization.gds.id
  }

  tags_custom = {
    System = "DevPlatform"
  }

  depends_on = [
    module.codebuild-github-role
  ]
}

module "codebuild-github-role" {
  source     = "../../../modules/codebuild-github-role"
  stack_name = "codebuild-github-role"
  parameters = {
    OneLoginRepositoryName = "devplatform-build-image"
    Environment = "dev"
    AWSOrganizationId = data.aws_organizations_organization.gds.id
  }

  tags_custom = {
    System = "DevPlatform"
  }
}
