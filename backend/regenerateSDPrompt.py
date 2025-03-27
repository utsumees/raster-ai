import json
import boto3
from botocore.exceptions import ClientError
from enum import Enum
import re

class models(Enum):
    claude_3_5 = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    claude_3_7 = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"

modelRegion = 'us-west-2'
modelId = "anthropic.claude-3-5-sonnet-20241022-v2:0"

def remove_codeblock(text):
    text = re.sub(r"```(json)?", "", text)
    text = re.sub(r"```", "", text)
    return text

def lambda_handler(event, context):
    try: 
        require = event['body']
        if type(require) == str:
            require = remove_codeblock(require)
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
        あなたは画像生成モデルStable Diffusionの専門家として、以下のプロセスを行います。
    
    
        ①ユーザが自然言語で記述した画像生成の説明文に基づき、Stable Diffusionが理解しやすい平易・具体的な言葉に「再解釈」を行い、Stable Diffusion用のプロンプトを作成しました。
        ②その結果、Stable Diffusionが画像を生成しました。生成画像をVLM（視覚言語モデル）が評価し、「Stable Diffusion用プロンプト」と「生成画像」の適合度合いを解析しました。その結果、画像生成が上手くいかなかった要素や、特に再解釈した用語が画像で正しく表現されなかった場合の改善提案がJSON形式で出力されています。
    
    
        あなたのタスクは、このVLMによる評価を踏まえ、Stable Diffusionモデルが適切に理解し、次回の画像生成を改善するため、再度Stable Diffusion用のプロンプトを修正・改善することです。
    
    
        以下の形式で入力される情報に基づき、次回以降のStable Diffusionによる画像生成がより的確になるように改善されたプロンプトを作成してください：
    
    
        【元のユーザ自然言語入力文】：
        （ユーザが画像生成したい内容を説明する文がここに挿入されます）
    
    
        【初回生成時のStable Diffusion用プロンプト】：
        （前回LLMが生成したプロンプトがここに記載されます）
    
    
        【VLMによる評価結果（JSON）】：
        （VLMが評価した要素ごとの一致状況・総合評価・再解釈語の改善提案を記載したJSONがここに挿入されます）
    
    
        あなたは、以下の手順でプロンプトを改善します：
    
    
        Step 1：
        VLM評価結果を精査し、"partially matches"や"does not match"となった要素を特定します。特に再解釈した要素の評価・改善案に注意してください。
    
    
        Step 2：
        "partially matches"や"does not match"となった要素、また再解釈した要素の改善提案を基に、Stable Diffusionプロンプトを明確に修正・改善します（表現の変更・追加・削除などを具体的に行います）。
    
    
        Step 3：
        改善を踏まえ、改善後のStable Diffusion用プロンプトを英語でカンマ区切りの形式で生成します。人物,物体,背景,色調,情景の詳細,雰囲気,イラストスタイルを明確なキーワードで含めます。
    
    
        あなたの出力は次の形式で行ってください：
    
        {{
          "description": （前回のプロンプトから、どの要素を、どのような表現・単語に変更または強調したか、改善の理由・意図を具体的に日本語の短い文で説明します）,
          "prompt": （改善した後のStable Diffusion向けプロンプトを英語で簡潔に、カンマ区切りの形式で提示してください）
        }}
    
    
        以上の指示を踏まえて、以下の情報を使用して改善したプロンプトを作成してください：
    
    
        【元のユーザ自然言語入力文】：
        {require['user_input']}
    
    
        【初回生成時のStable Diffusion用プロンプト】:
        {require['prompt']}
    
        【VLMによる改善提案】
        {require['suggestion']}
        """}],
                }
            ],
            additionalModelRequestFields={
                "thinking": {"type": "enabled", "budget_tokens": 1024},
            },
        )

        message = response["output"]["message"]

        user_id = require['user_id']
        connection_id = require['connection_id']
         # Extract and print the response text.
        output = message["content"][1]['text']
        # print(json.dumps(output, indent=2, ensure_ascii=False))
        body = json.dumps({"user_id": user_id, "connection_id": connection_id, "user_input": require['user_input'], "output": output})
        return {
            'statusCode': 200,
            'body': body
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
             "body": json.dumps({"error": str(e)})
        }