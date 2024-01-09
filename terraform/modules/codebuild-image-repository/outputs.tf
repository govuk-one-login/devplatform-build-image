output "stack_id" {
  value = aws_cloudformation_stack.deploy.id
}

output "stack_outputs" {
  value = aws_cloudformation_stack.deploy.outputs
}

output "stack_tags" {
  value = aws_cloudformation_stack.deploy.tags_all
}
