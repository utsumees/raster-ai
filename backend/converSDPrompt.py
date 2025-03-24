import json
import boto3
from botocore.exceptions import ClientError
from enum import Enum

class models(Enum):
    claude_3_5 = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    claude_3_7 = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"

modelRegion = 'us-west-2'
modelId = "anthropic.claude-3-5-sonnet-20241022-v2:0"

def lambda_handler(event, context):
    # TODO implement
    
    require = event['body']
    user_id = require['user_id']
    connection_id = require['connection_id']
    if type(require) == str:
        require = json.loads(require)
    # print(require.keys())

    client = boto3.client("bedrock-runtime")

    # content = []
    # if "prompt" in require.keys():
    #     content.append({"text": require['prompt']})
    # if "image" in require.keys():
    #     content.append({"image": {"source": { "bytes": require['image']}, "format": "png"}})
    # # print(content)
    # message = {
    #     "content": content
    # }

    # print(message[0].content[1])
    # print(message)
    response = client.converse(
        modelId=models.claude_3_7.value,
        messages=[
            {
                "role": "user",
                "content": [{'text': f"""
あなたは画像生成モデルStable Diffusionを熟知した専門家であり、ユーザがStable Diffusionを使って理想的な画像を生成できるようにサポートする役割を持っています。

ユーザは自由な日本語の自然言語で、生成したい画像の内容や状況を説明します。
しかし、Stable Diffusionの画像生成モデルは、モデルが十分に学習していない概念・語彙（特に専門用語、比較的新しい言葉、複雑な抽象語など）を理解しにくく、そのままの用語をStable Diffusionへのプロンプトとして入力してしまうと、ユーザの求める通りの画像が生成できないことがあります。

そこでまず、あなたのタスクはモデルが苦手な可能性のある概念・用語について、Stable Diffusionがより一般的に把握しやすい、具体的でシンプルな用語・詳しい言葉への再解釈を行い、その再解釈を踏まえたうえで、Stable Diffusion用のプロンプト（後ほど別のAIがStable Diffusion用のキーワードに変換できるような明確かつ具体的で詳細な英語のプロンプト）を用意します。

手順は以下の通りです：

Step 1「解釈」

入力文をよく読み、Stable Diffusionのモデルが苦手と思われる表現や語彙を特定します。
モデルが理解しやすい具体的な物体・形状・構成・情景・要素・類似のもので言い換えます。
特に専門的・抽象的・目新しい用語は、平易で一般的・画像として描きやすい用語に言い換えます。
Step 2「再解釈した結果に基づくプロンプト作成」

上記の再解釈をもとに、Stable Diffusion用の画像生成プロンプトとして、イメージがはっきりと伝達される、英語の具体的でシンプル、かつ詳細な文章をカンマ区切りで作成します。
人物,物体,背景,色彩,構図,雰囲気,イラストスタイルなどを明確に含め、Stable Diffusionが理解しやすい表現を選択します。
出力するプロンプトには、Stable Diffusion用のネガティブプロンプトは記載しないでください。
以下のようなjson形式で出力してください。

{{
  "interpretation": (元の入力文中でStable Diffusionが苦手な可能性がある部分を平易な語へ言い換える、または詳しく具体化する。),
  "prompt": (再解釈を基にしたStable Diffusion向け英語プロンプトをカンマ区切りで記述する。)
}}

それでは、以下のユーザ入力文に対して、上述したような形式で出力してください：

{require['user_input']}
    """}],
            }
        ],
        additionalModelRequestFields={
            "thinking": {"type": "enabled", "budget_tokens": 1024},
        },
    )

    message = response["output"]["message"]

     # Extract and print the response text.
    output = message["content"][1]['text']
    # print(json.dumps(output, indent=2, ensure_ascii=False))
    body = json.dumps({"user_id": user_id, "connection_id": connection_id, "user_input": require['user_input'], "output": output})
    return {
        'statusCode': 200,
        'body': body
    }


    # return {
    #     'statusCode': 200,
    #     'body': json.dumps(str(body))
    # }