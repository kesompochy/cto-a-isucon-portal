resource "aws_amplify_app" "isucon_portal" {
  name         = "isucon-portal"
  repository   = var.repository
  access_token = var.access_token

  build_spec = file("${path.module}/build_spec.yaml")

  enable_auto_branch_creation = true

  auto_branch_creation_patterns = var.auto_branch_creation_patterns

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "https://hikakin-tv.com"
    status = "302"
    target = "https://www.hikakin-tv.com"
  }
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  environment_variables = {
    ENV                = "test"
    SHEET_API_ENDPOINT = var.sheet_api_endpoint
  }

  iam_service_role_arn = aws_iam_role.amplify_service_role.arn
}

resource "aws_amplify_branch" "master" {
  app_id      = aws_amplify_app.isucon_portal.id
  branch_name = "master"
}

# Create IAM role for Amplify
resource "aws_iam_role" "amplify_service_role" {
  name = "AmplifyConsoleServiceRole-AmplifyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "amplify.amazonaws.com"
        }
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:amplify:${var.region}:${var.account_id}:apps/*"
          }
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}
