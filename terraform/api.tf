resource "aws_dynamodb_table" "portal_scores" {
  name         = "portal_scores"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "team_id"

  attribute {
    name = "team_id"
    type = "S"
  }
}

resource "aws_appsync_graphql_api" "portal_api" {
  name                = "portal_api"
  authentication_type = "API_KEY"

  additional_authentication_provider {
    authentication_type = "AMAZON_COGNITO_USER_POOLS"
    user_pool_config {
      aws_region     = "ap-northeast-1"
      user_pool_id   = aws_cognito_user_pool.main.id
    }
  }

  schema = file("${path.module}/schema.graphql")
}

resource "aws_iam_role" "portal_api_datasource_role" {
  name = "portal_api_datasource_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "appsync.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_cognito_user_pool" "main" {
  name = "portal_user_pool"
}

resource "aws_cognito_user_pool_client" "main" {
  name = "portal_user_pool_client"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name = "portal_identity_pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id = aws_cognito_user_pool_client.main.id
    provider_name = replace(aws_cognito_user_pool.main.endpoint, "https://", "")
  }
}

resource "aws_appsync_datasource" "portal_api_datasource" {
    api_id           = aws_appsync_graphql_api.portal_api.id
    name             = "portal_api_datasource"
    type             = "AMAZON_DYNAMODB"
    service_role_arn = aws_iam_role.portal_api_datasource_role.arn

    dynamodb_config {
        table_name = aws_dynamodb_table.portal_scores.name
    }
}

resource "aws_appsync_resolver" "Query_getTeamScore" {
  api_id = aws_appsync_graphql_api.portal_api.id
  type = "Query"
  field = "getTeamScore"
  
  data_source = aws_appsync_datasource.portal_api_datasource.name

  request_template  = file("${path.module}/templates/getTeamScore-request.vtl")
  response_template = file("${path.module}/templates/getTeamScore-response.vtl")
}

resource "aws_appsync_resolver" "Mutation_updateTeamScore" {
  api_id = aws_appsync_graphql_api.portal_api.id
  type = "Mutation"
  field = "updateTeamScore"
  
  data_source = aws_appsync_datasource.portal_api_datasource.name

  request_template  = file("${path.module}/templates/updateTeamScore-request.vtl")
  response_template = file("${path.module}/templates/updateTeamScore-response.vtl")
}

resource "aws_appsync_api_key" "api_key" {
  api_id = aws_appsync_graphql_api.portal_api.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
  description = "ID of the Cognito User Pool Client"
}

output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
  description = "ID of the Cognito Identity Pool"
}