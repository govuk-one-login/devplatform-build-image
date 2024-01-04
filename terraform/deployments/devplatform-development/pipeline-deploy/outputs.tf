output "gds_org_id" {
  value = data.aws_organizations_organization.gds.id
}

output "codebuild-image-pipeline_stack_id" {
  value = module.codebuild-image-pipeline.stack_id
}
output "codebuild-image-pipeline_stack_outputs" {
  value = module.codebuild-image-pipeline.stack_outputs
}
output "codebuild-image-pipeline_stack_tags" {
  value = module.codebuild-image-pipeline.stack_tags
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