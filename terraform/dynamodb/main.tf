resource "aws_dynamodb_table" "isucon_scores" {
  name           = "isucon_scores"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "team_id"

  attribute {
    name = "team_id"
    type = "N"
  }

  attribute {
    name = "score"
    type = "N"
  }

  attribute {
    name = "last_updated"
    type = "S"
  }

  # More attributes if needed...

  tags = {
    Environment = "production"
    Name        = "isucon_scores"
  }
}