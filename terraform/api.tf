resource "aws_dynamodb_table" "portal_scores" {
  name         = "portal_scores"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "team_id"
  range_key    = "timestamp"

  attribute {
    name = "team_id"
    type = "N"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

resource "aws_appsync_graphql_api" "portal_api" {
  name                = "portal_api"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  user_pool_config {
    aws_region     = "ap-northeast-1"
    user_pool_id   = aws_cognito_user_pool.main.id
    default_action = "ALLOW"
  }

  additional_authentication_provider {
    authentication_type = "API_KEY"
  }

  schema = file("${path.module}/schema.graphql")
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

resource "aws_iam_policy" "portal_api_datasource_policy" {
  name   = "portal_api_datasource_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/portal_scores"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "portal_api_datasource_policy_attachment" {
  role       = aws_iam_role.portal_api_datasource_role.name
  policy_arn = aws_iam_policy.portal_api_datasource_policy.arn
}

resource "aws_appsync_resolver" "Query_getAllScores" {
  api_id = aws_appsync_graphql_api.portal_api.id
  type = "Query"
  field = "getAllScores"
  
  data_source = aws_appsync_datasource.portal_api_datasource.name

  request_template  = file("${path.module}/templates/getAllScores-request.vtl")
  response_template = file("${path.module}/templates/getAllScores-response.vtl")
}

resource "aws_appsync_resolver" "Mutation_updateTeamScore" {
  api_id = aws_appsync_graphql_api.portal_api.id
  type = "Mutation"
  field = "updateTeamScore"
  
  data_source = aws_appsync_datasource.portal_api_datasource.name

  request_template  = file("${path.module}/templates/updateTeamScore-request.vtl")
  response_template = file("${path.module}/templates/updateTeamScore-response.vtl")
}

resource "aws_cognito_user_pool" "main" {
  name = "portal_user_pool"
}

resource "aws_cognito_user_pool_client" "main" {
  name = "portal_user_pool_client"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_appsync_api_key" "api_key" {
  api_id = aws_appsync_graphql_api.portal_api.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.main.id
  description = "ID of the Cognito User Pool Client"
}