# メモアプリ

メモを登録、表示、編集、削除できる Sinatra アプリケーションです。

## 必要なもの

- Ruby 3.4.10
- Bundler 4.0.20
- PostgreSQL 18.6

## セットアップ

```sh
bundle install
```

## データベースの準備

データベースを作成します。テーブル作成はアプリ起動時に自動で行われます。

```sh
createdb memo_app
```

## 起動方法

```sh
bundle exec ruby app.rb
```

起動後、ブラウザで <http://localhost:4567/> を開きます。
