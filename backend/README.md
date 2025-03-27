# Raster.ai バックエンド設計

バックエンドは主にAWS Lambdaで構築しています。

## チャット部分


| エンドポイント | メソッド | リクエストJSON | レスポンスJSON | 備考 |
| --- | --- | --- | --- | --- |
| `/login` | POST | `<pre>{ "user_id": "example@example.com", "password": "yourpassword" }</pre>` | `<pre>{}</pre>` | ログイン |
| `/llm` | POST | - | - | LLMへ問い合わせ |
| `/chat` | WebSocket (`$connect`, `$disconnect`, `$default`, `$addmessage`) | - | - | WebSocket接続に使用 |
| `/chat.append` | WebSocket | - | - | 新たにチャットに追加する |
| `/generateImage` | POST | - | - | 画像生成リクエスト |

websocketセッションの識別にはプロンプトのハッシュ値を利用する

## データベース設計

### chat

| キー         | 型        | 説明                             |
|--------------|-----------|--------------------------------|
| user_id      | TEXT      | チャット所有者のユーザーID（NOT NULL）       |
| message_id   | SERIAL    | メッセージID（ユーザー単位でAUTO INCREMENT） |
| post_by      | TEXT      | 発言者（NULL許容）                    |
| text         | TEXT      | メッセージ本文（NULL許容）                |
| image        | TEXT      | S3画像データURL                     |
| post_at      | TIMESTAMP | 投稿日時（NULL許容）                   |

### users

| キー        | 型    | 説明                            |
|-------------|--------|---------------------------------|
| user_id     | TEXT   | メールアドレス（PRIMARY KEY）  |
| password    | TEXT   | ハッシュ化されたパスワード      |
| session_id  | TEXT   | セッションID（NULL許容）        |


```sql
-- 依存する users テーブルを先に削除
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS chats;

-- chats テーブル作成（session_id を TEXT + UNIQUE に変更済み）
CREATE TABLE chats (
  user_id TEXT NOT NULL,
  message_id SERIAL,
  post_by TEXT,
  text TEXT,
  image TEXT,
  post_at TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (user_id, message_id)
);

-- users テーブル作成
CREATE TABLE users (
  user_id TEXT PRIMARY KEY,         -- email
  password TEXT NOT NULL,           -- ハッシュ前提
  session_id TEXT DEFAULT NULL     -- chats.session_id を参照
);

```

## llm

| キー | 型 | 説明 |
| --- | --- | --- |
| prompt | str | llmに渡されるプロンプト |
| image | ? | imageのpath |
| system_prompt | str | システム側に渡される固有の指示 |

## AI周り

| エンドポイント | メソッド | リクエストJSON | レスポンスJSON | 説明 |
| --- | --- | --- | --- | --- |
| `/convertSDPrompt` | POST | `<pre>{ "user_id": "user_id", "user_input": "user_input" }</pre>` | `<pre>{ "user_id": "user_id", "user_input": "user_input", "prompt": "prompt" }</pre>` | SD用プロンプト変換 |
| `/image_generation` | POST | `<pre>{ "user_input": "user_input", "output": { "interruption": "interruption", "prompt": "prompt" } }</pre>` | `<pre>{ "user_input": "user_input", "prompt": "prompt", "image_uuid": "image_uuid" }</pre>` | 画像生成 |
| `/evaluate_image` | POST | `<pre>{ "prompt": "prompt", "image_uuid": "image_uuid" }</pre>` | `<pre>{ "user_input": "user_input", "overall": "overall", "suggestion": "suggestion" }</pre>` | LLMによる画像評価 |
| `/regenerateSDPrompt` | POST | `<pre>{ "user_input": "user_input", "prompt": "prompt", "suggestion": "suggestion" }</pre>` | `<pre>{ "prompt": "prompt" }</pre>` | 改善されたプロンプト再生成 |
| `/judge` | POST | `<pre>{ "user_input": "user_input", "prompt": "prompt", "overall": "overall" }</pre>` | `<pre>{ "user_id": "user_id", "user_input": "user_input", "prompt": "prompt", "roop": 1 }</pre>` | 判定処理 |

---

## 処理の流れ

1. ユーザがプロンプトを打つ
2. ===== ループ終了 =====
llmが解釈とsd向けのプロンプトを生成
3. sdが画像生成
4. llmのプロンプトと、sdの画像を入力→評価と改善点を出力
5. 1のプロンプトと2のプロンプト、4の改善点を入れる
===== ループ終了 =====

# Webhook

jsonテンプレート

```json
{
	"type": "image_generator", // judge_llm
	"contents": {"image_url": "S3URL"}
}
```

```json
{
	"type": "judge_llm", // judge_llm
	"contents": {
		"text": "a",
		"image_url": "S3URL", // もしあれば
		"is_stream": true // false (最初の1文字だけはfalse, あとはメッセージが終了するまでtrue）
	}
}
```

### type一覧

- converSDPrompt
- image_generation
- evaluate_image
- judge
