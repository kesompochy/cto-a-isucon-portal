#!/bin/bash

# .env ファイルから環境変数を読み込む
export $(grep -v '^#' .env | xargs)

# コマンドライン引数からチームIDとスコアを読み込む
TEAM_ID=$1
SCORE=$2

# エラーチェック: 引数が2つ与えられているか確認
if [ "$#" -ne 2 ]; then
    echo "使用法: ./update-score.sh [チームID] [スコア]"
    exit 1
fi

# 現在のUNIXタイムスタンプを取得
TIMESTAMP=$(date +%s)

# GraphQL クエリを実行
curl -XPOST -H "Content-Type:application/json" -H "x-api-key:$API_KEY" -d "{
  \"query\": \"mutation { updateTeamScore(team_id: $TEAM_ID, pass: true, score: $SCORE, success: 0, fail: 0, messages: [\\\"message1\\\"], timestamp: $TIMESTAMP) { team_id pass score success fail messages timestamp } }\"
}" "$ENDPOINT"