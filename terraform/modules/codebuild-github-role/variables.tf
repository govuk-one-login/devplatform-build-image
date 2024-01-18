variable "stack_name" {
  type = string
}

variable "template_body" {
  type    = string
  default = "../../../codebuild-github-role/template.yaml"
}

variable "policy_url" {
  type    = string
  default = ""
}

variable "capabilities" {
  type    = list(string)
  default = ["CAPABILITY_NAMED_IAM"]
}

variable "on_failure" {
  type    = string
  default = "ROLLBACK"
}

variable "iam_role_arn" {
  type    = string
  default = ""
}

variable "parameters" {
  description = "A Map of parameters to pass to the CloudFormation template at runtime"
  type = object({
    OneLoginRepositoryName = string
    Environment = string
  })
}

variable "tags" {
  description = "A Map of tags - with optional default values"
  type = object({
    Product     = optional(string, "GOV.UK Sign In")
    System      = optional(string, "Authentication")
    Environment = optional(string, "build")
  })

  default = {
    Product     = "GOV.UK Sign In"
    System      = "Authentication"
    Environment = "build"
  }
}

variable "tags_custom" {
  description = "Optional custom resource tags"
  type        = map(string)
  default     = {}
}
