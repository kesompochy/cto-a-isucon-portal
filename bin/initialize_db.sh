#!/bin/bash

# Table name
TABLE_NAME="portal_scores"

# Delete the table
aws dynamodb delete-table --table-name $TABLE_NAME --region ap-northeast-1

# Wait until the table is deleted
aws dynamodb wait table-not-exists --table-name $TABLE_NAME --region ap-northeast-1

# Create the table
aws dynamodb create-table --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=team_id,AttributeType=S AttributeName=timestamp,AttributeType=N \
  --key-schema AttributeName=team_id,KeyType=HASH AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST --region ap-northeast-1

# Wait until the table is created
aws dynamodb wait table-exists --table-name $TABLE_NAME --region ap-northeast-1

# Check if TEAM_COUNT is set
if [ -z "${TEAM_COUNT}" ]; then
  echo "Please set the TEAM_COUNT environment variable."
  exit 1
fi

# Insert initial scores for each team
for i in $(seq 1 $TEAM_COUNT)
do
  aws dynamodb put-item \
    --table-name portal_scores \
    --item '{
        "team_id": {"S": "'"$i"'"},
        "score": {"N": "0"},
        "pass": {"BOOL": false},
        "success": {"N": "0"},
        "fail": {"N": "0"},
        "timestamp": {"N": "'$(date +%s)'"},
        "messages": {"L": []}
    }' \
    --region ap-northeast-1
done