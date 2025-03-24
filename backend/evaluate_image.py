import json
import boto3
import re
import base64
import httpx

s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")
required_keys = {"results", "overall", "suggestion"}

def validate_json_partial(data, required_keys):
    return required_keys.issubset(data.keys())

def is_valid_json(text):
    try:
        json.loads(text)
        return True
    except json.JSONDecodeError:
        return False

def remove_codeblock(text):
    text = re.sub(r"```(json)?", "", text)
    text = re.sub(r"```", "", text)
    return text

def extract_codeblock(text):
    code_blocks = re.findall(r'```(.*?)```', text, re.DOTALL)
    cleaned_code_blocks = [re.sub(r'^\s*json\s*', '', block.strip()) for block in code_blocks]
    return cleaned_code_blocks

def lambda_handler(event, context):
    try: 
        body = json.loads(remove_codeblock(event["body"]))
        user_input = body["user_input"]
        user_id = body["user_id"]
        connection_id = body["connection_id"]
        prompt = body["prompt"]
        image_uuid = body["image_uuid"]
        image_url = f"https://tora-generated-images.s3.us-west-2.amazonaws.com/{image_uuid}.png"
        
        # 画像送信
        apigw = boto3.client(
            'apigatewaymanagementapi',
            endpoint_url=f"https://emed5h4bp1.execute-api.us-west-2.amazonaws.com/v1?userid=test&bot"
        )
        data = {
	        "type": "image_generation",
	        "contents": {"image_url": image_url}
        }
        apigw.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps(data)
        )

        image_media_type = "image/jpeg"
        image = base64.standard_b64encode(httpx.get(image_url).content).decode("utf-8")

        payload = f"""
        以下のStable Diffusion用プロンプトと生成された画像を比較し、画像がプロンプト内容を的確に反映しているか評価してください。
        評価結果は以下のJSON形式のみで出力し、それ以外の説明やコメントなどのテキストは一切出力しないでください。

        Stable Diffusion用プロンプト：
        {prompt}


        評価基準：

        各要素（人物・物体・背景・スタイル・色調・構図・情景など）ごとに、以下の基準で評価してください。
        fully matches（完全に描写されている）
        partially matches（部分的に描写されているが不十分である）
        does not match（全く描写されていない）
        特にStable Diffusionが苦手と考えられ、再解釈された専門用語が画像に正しく描写されているか詳細に評価してください。
        最後に総合評価を以下の基準で必ず行ってください。
        3: Excellent（プロンプトのすべての要素が明確に適切に描写されている場合）
        2: Good（ほとんどの要素は描写されているが、一部が適切に描写されていない場合）
        1: Poor（不足要素・差異が多く、プロンプト内容を十分反映していない）
        0: Completely Incorrect（プロンプトの内容と全くかけ離れている場合）
        必ず以下のJSON形式のみを出力してください：

        `{{
            "results": {{
                "item1": "(fully matches / partially matches / does not match)",
                "item2": "(fully matches / partially matches / does not match)"
                //(必要な要素ごとに続ける)
            }},
            "overall": "(3 / 2 / 1 / 0)",
            "suggestion": "(差異や不足が顕著な場合のみ具体的な改善策を日本語で記載する。問題なければ「特に無し」と記載。)"
        }}`

        """

        content = [
            {
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": image_media_type,
                    "data": image,
                }
            },
            {   "type": "text",
                "text": payload
            }

        ]

        body = json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [
                {
                    "role": "user",
                    "content": content,
                }
            ]
        })
        
        while True:
            response = bedrock.invoke_model(
                modelId="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
                contentType="application/json",
                accept="application/json",
                body=body
            )
            response_body = json.loads(response['body'].read())
            output = response_body['content'][0]['text']
            print(output)
            if not is_valid_json(output):
                try: 
                    output = extract_codeblock(output)[0]
                    if validate_json_partial(json.loads(output), required_keys):
                        break
                except Exception as e:
                    print(e)
                    continue

        

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"user_id": user_id, "connection_id": connection_id, "user_input": user_input, "prompt": prompt, "evaluation": output})
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
             "body": json.dumps({"error": str(e)})
        }

