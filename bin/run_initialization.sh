#!/bin/bash

# パラメータチェック
if [ "$#" -ne 1 ]; then
    echo "Usage: ./run_initialization.sh NUM_TEAMS"
    exit 1
fi

# TEAM_COUNT 環境変数を設定
export TEAM_COUNT=$1

# initialize_db.sh スクリプトの実行
echo "Initializing database..."
./initialize_db.sh

# initialize_users.sh スクリプトの実行
echo "Initializing users..."
./initialize_users.sh $1

echo "Initialization completed."