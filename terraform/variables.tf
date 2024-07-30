variable "access_token" {
  description = "Access token for the AWS Amplify app to access the repository. The needed permission is `Webhooks: Read and Write`."
  type        = string
}

variable "repository" {
  description = "Repository URL for the Amplify CD"
  type        = string
  default     = "https://github.com/kesompochy/cto-a-isucon-portal"
}

variable "ops_repository" {
  description = "Repository URL for the operations workflow"
  type        = string
  default     = "cto-a/private-isu-ops"
}

variable "auto_branch_creation_patterns" {
  description = "Branch name for the Amplify CD"
  type        = list(string)
  default     = ["master", "feat/**"]
}

variable "sheet_api_endpoint" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "account_id" {
  type = string
}

variable "team_count" {
  type    = number
  default = 40
}
