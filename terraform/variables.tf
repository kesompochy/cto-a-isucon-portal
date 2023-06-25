variable "access_token" {
  description = "Access token for the AWS Amplify app"
  type        = string
}

variable "repository" {
  description = "Repository URL for the Amplify CD"
  type        = string
  default     = "https://github.com/kesompochy/cto-a-isucon-portal"
}

variable "auto_branch_creation_patterns" {
  description = "Branch name for the Amplify CD"
  type        = list(string)
  default     = ["master", "feat/**"]
}

variable "sheet_api_endpoint" {
  description = "API key for Google Sheets"
  type        = string
}