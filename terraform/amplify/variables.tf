variable "access_token" {
  description = "Access token for the AWS Amplify app"
  type        = string
}

variable "repository" {
  description = "Repository URL for the Amplify CD"
  type        = "string"
  default     = "https://github.com/kesompochy/cto-a-isucon-portal"
}