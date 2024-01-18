resource "aws_cloudformation_stack" "deploy" {
  name         = local.stack.name
  parameters   = local.parameters
  template_body = file("${path.module}/${local.stack.template_body}")
  policy_url   = local.stack.policy_url
  capabilities = local.stack.capabilities
  on_failure   = local.stack.on_failure
  iam_role_arn = local.stack.iam_role_arn

  tags = local.stack_tags
}
