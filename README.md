# わくわくISUCON大会のポータル機能を集約するリポジトリだよ

## 機能一覧

- チームのスコアを保存するデータストア
- 全時系列の全チームのスコアをフェッチして描画するフロントエンド
- データフェッチとスコアの更新を受け付けるWeb API

## 他コンポーネントとの連携

### API

スコア更新APIは、ベンチマーカーからのみ叩かれることを意図しています。
現在はAPIキーをベンチマーカーのみが持つことでその目的を達成しています。

データを更新する際はベンチマーカーから次のようにPOSTしてください。

```
> curl -XPOST -H "Content-Type:application/json" -H "x-api-key:CREDENTIAL_API_KEY" -d '{
  "query": "mutation { updateTeamScore(team_id: \"1\", pass: true, score: 10, success: 1, fail: 0, messages: [\"message1\"], timestamp: 1934567890) { team_id pass score success fail messages timestamp } }"
}' 'https://APPSYNC_API_ENDPOINT/graphql'
{"data":{"updateTeamScore":{"team_id":"1","pass":true,"score":10,"success":1,"fail":0,"messages":["message1"],"timestamp":1934567890}}}%
```

秘匿情報やエンドポイントはAWSコンソールから確認してください。それぞれAppSyncのページから確認できます。

lambdaから叩かれると仮定した場合、最終的にはlambdaにアクセスポリシーを与えるようにしてAPIキーによる認証は廃止したいです。

### チーム管理

フロントエンドがCognitoでチームを認証します。

チームIDとパスワードでの認証になるため、運用の際は各チームにチームIDと初期パスワードを渡す運用になるかと思います。

## ディレクトリごとの話

### bin/

シェルスクリプトを置きます。

#### `initialize_db.sh`

スコアの保存DBを初期化します。テーブルを削除して作り直して初期データを入れています。

### frontend/

htmlとかjsとかcssとかを置きます。
開発はVue.js + TypeScript + Viteで行います。

### terraform/

リソースの管理を行います。

## アーキテクチャの話

### 全体像

- Amplifyでフロントエンドのホスティングをする
  - このリポジトリのmasterブランチからwebhookを飛ばしてCI/CDを行う
- DynamoDBでデータストアを行う
  - NoSQLってやつ
- AppSyncでGraphQL APIを提供する
  - Cognitoによるユーザーごとの認可と、APIキーによる認可を行う
  - 先述の通り将来的にはAPIキーは廃止してIAMにする
  - ユーザーが叩くものはCognitoで、特定コンポーネントのみが叩くものはAPIキー（IAM）で認可する
- Cognitoでチームごとの認証をする
  - 将来的にフロントエンドからベンチマーカを叩けるようにしたいから
- Amplifyでホストされたフロントエンドがamplify-cliで認証とAPI叩きを行う