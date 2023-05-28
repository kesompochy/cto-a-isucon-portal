#!/bin/bash

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