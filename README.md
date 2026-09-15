# メモアプリ

メモを登録、表示、編集、削除できる Sinatra アプリケーションです。

## 必要なもの

- Ruby 3.4.10
- Bundler 4.0.20

## セットアップ

```sh
bundle install
```

## 起動方法

```sh
bundle exec ruby app.rb
```

起動後、ブラウザで <http://localhost:4567/> を開きます。

## データ保存

メモのデータは `data/memos.json` に保存します。
パスが存在しない場合は`data/memos.json`を自動作成します。
