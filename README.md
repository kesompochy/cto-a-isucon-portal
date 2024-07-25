# わくわく大会のポータル機能を集約するリポジトリだよ

チームごとに時系列でスコアを高めていく大会のポータル画面を提供します。

## セットアップ

```sh
$ aws configure sso --profile ctoa2024
# 情報を入力してProfileを作成
$ aws sso login --profile ctoa2024
$ cp terraform/terraform.tfvars.sample terraform/terraform.tfvars
# terraform/terraform.tfvars に必要な情報を入力
$ cd terraform
$ terraform init
$ terraform apply
```

## 機能一覧

- チームのスコアを保存するデータストア
- 全時系列の全チームのスコアをフェッチして描画するフロントエンド
- データフェッチとスコアの更新を受け付ける Web API

## 他コンポーネントとの連携

### API

スコア更新 API は、ベンチマーカーからのみ叩かれることを意図しています。
現在は API キーをベンチマーカーのみが持つことでその目的を達成しています。

データを更新する際はベンチマーカーから次のように POST してください。

```
> curl -XPOST -H "Content-Type:application/json" -H "x-api-key:CREDENTIAL_API_KEY" -d '{
  "query": "mutation { updateTeamScore(team_id: 1, pass: true, score: 10, success: 1, fail: 0, messages: [\"message1\"], timestamp: 1934567890) { team_id pass score success fail messages timestamp } }"
}' 'https://APPSYNC_API_ENDPOINT/graphql'
{"data":{"updateTeamScore":{"team_id":1,"pass":true,"score":10,"success":1,"fail":0,"messages":["message1"],"timestamp":1934567890}}}%
```

秘匿情報やエンドポイントは AWS コンソールから確認してください。それぞれ AppSync のページから確認できます。

lambda から叩かれると仮定した場合、最終的には lambda にアクセスポリシーを与えるようにして API キーによる認証は廃止したいです。

### チーム管理

フロントエンドが Cognito でチームを認証します。

チーム ID とパスワードでの認証になるため、運用の際は各チームにチーム ID と初期パスワードを渡す運用になるかと思います。

## ディレクトリごとの話

### bin/

シェルスクリプトを置きます。

#### `initialize_db.sh`

スコアの保存 DB を初期化します。テーブルを削除して作り直して初期データを入れています。

### frontend/

html とか js とか css とかを置きます。
開発は Vue.js + TypeScript + Vite で行います。

### terraform/

リソースの管理を行います。

## アーキテクチャの話

### 全体像

- Amplify でフロントエンドのホスティングをする
  - このリポジトリの master ブランチから webhook を飛ばして CI/CD を行う
- DynamoDB でデータストアを行う
  - NoSQL ってやつ
- AppSync で GraphQL API を提供する
  - Cognito によるユーザーごとの認可と、API キーによる認可を行う
  - 先述の通り将来的には API キーは廃止して IAM にする
  - ユーザーが叩くものは Cognito で、特定コンポーネントのみが叩くものは API キー（IAM）で認可する
- Cognito でチームごとの認証をする
  - 将来的にフロントエンドからベンチマーカを叩けるようにしたいから
- Amplify でホストされたフロントエンドが amplify-cli で認証と API 叩きを行う
