output "gds_org_id" {
  value = data.aws_organizations_organization.gds.id
}

output "codebuild-github-role_stack_id" {
  value = module.codebuild-github-role.stack_id
}
output "codebuild-github-role_stack_outputs" {
  value = module.codebuild-github-role.stack_outputs
}
output "codebuild-github-role_stack_tags" {
  value = module.codebuild-github-role.stack_tags
}

output "codebuild-promotion-github-role_stack_id" {
  value = module.codebuild-promotion-github-role.stack_id
}
output "codebuild-promotion-github-role_stack_outputs" {
  value = module.codebuild-promotion-github-role.stack_outputs
}
output "codebuild-promotion-github-role_stack_tags" {
  value = module.codebuild-promotion-github-role.stack_tags
}

output "codebuild-image-ecr_stack_id" {
  value = module.codebuild-image-ecr.stack_id
}
output "codebuild-image-ecr_stack_outputs" {
  value = module.codebuild-image-ecr.stack_outputs
}
output "codebuild-image-ecr_stack_tags" {
  value = module.codebuild-image-ecr.stack_tags
}

output "codebuild-promotion-image-ecr_stack_id" {
  value = module.codebuild-promotion-image-ecr.stack_id
}
output "codebuild-promotion-image-ecr_stack_outputs" {
  value = module.codebuild-promotion-image-ecr.stack_outputs
}
output "codebuild-promotion-image-ecr_stack_tags" {
  value = module.codebuild-promotion-image-ecr.stack_tags
}
