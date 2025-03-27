import json
import re
import boto3

def remove_codeblock(text):
    text = re.sub(r"```(json)?", "", text)
    text = re.sub(r"```", "", text)
    return text

def lambda_handler(event, context):
    # TODO implement
    try: 
        require = event['body']
        require = remove_codeblock(require)
        require  = json.loads(require)

        user_id = require['user_id']
        connection_id = require['connection_id']
        user_input = require['user_input']
        prompt = require['prompt']
        evaluation = require['evaluation']
        match = re.search(r'"overall":\s*"([^"]+)"', evaluation)
        if not match:
            return

        overall = match.group(1)

        match = re.search(r'"suggestion":\s*"([^"]+)"', evaluation)
        if not match:
            return

        suggestion = match.group(1)

        # 改善点送信
        apigw = boto3.client(
            'apigatewaymanagementapi',
            endpoint_url=f"*************************"
        )
        print(type(suggestion))
        for i, s in enumerate("生成画像の改善点："+suggestion):
            is_stream = False if i == 0 else True
            data = {
	            "type": "evaluate_image",
	            "contents": {
		        "text": s,
		        # "image_url": "S3URL", 
		        "is_stream": is_stream
	            }
            }
            apigw.post_to_connection(
                Data=json.dumps(data),
                ConnectionId=connection_id
            )
            
        result = 1
        judge_comment = "改善点を踏まえて改めて生成した方が良さそうだ．"
        if int(overall) >= 3:
            result = 0
            judge_comment = "再生成は必要なさそうだ．"

        for i, s in enumerate(judge_comment):
            is_stream = False if i == 0 else True
            data = {
	            "type": "judge",
	            "contents": {
		        "text": s,
		        "is_stream": is_stream
	            }
            }
            apigw.post_to_connection(
                Data=json.dumps(data),
                ConnectionId=connection_id
            )

        return {
            'statusCode': 200,
            'roop': result,
            'body': json.dumps({"user_id": user_id, "connection_id": connection_id, "user_input": user_input, "prompt": prompt, "suggestion": suggestion})
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
             "body": json.dumps({"error": str(e)})
        }
