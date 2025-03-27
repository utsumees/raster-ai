import json
import boto3
import base64
import uuid
import re

s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")

def remove_codeblock(text):
    text = re.sub(r"```(json)?", "", text)
    text = re.sub(r"```", "", text)
    return text

def lambda_handler(event, context):
    try:
        body = json.loads(remove_codeblock(event["body"]))
        output = body["output"]

        match = re.search(r'"prompt":\s*"([^"]+)"', output)
        if not match:
            return

        prompt = match.group(1)
        print(prompt)

        user_input = body["user_input"]
        user_id = body["user_id"]
        connection_id = body["connection_id"]

        # プロンプト送信
        apigw = boto3.client(
            'apigatewaymanagementapi',
            endpoint_url=f"*************************"
        )
        for i, s in enumerate(prompt):
            is_stream = False if i == 0 else True
            data = {
	            "type": "converSDPrompt",
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

        modelRegion = "us-west-2"
        modelId = "stability.stable-image-ultra-v1:1"

        body = json.dumps({
            "prompt": prompt,
            "mode": "text-to-image",
            "aspect_ratio": "1:1",
            "output_format": "png"  
        })

        response = bedrock.invoke_model(
            modelId=modelId,
            contentType="application/json",
            accept="application/json",
            body=body
        )

        output_body = json.loads(response["body"].read().decode("utf-8"))
        while "images" not in output_body:
            # yobu 
            response = bedrock.invoke_model(
                modelId=modelId,
                contentType="application/json",
                accept="application/json",
                body=body
            )
            output_body = json.loads(response["body"].read().decode("utf-8"))
        base64_output_image = output_body["images"][0] # 
        image_data = base64.b64decode(base64_output_image)

        bucket_name = "tora-generated-images"

        image_uuid = str(uuid.uuid4())
        image_key = f"{image_uuid}.png"

        s3.put_object(Bucket=bucket_name, Key=image_key, Body=image_data, ContentType= "image/png")

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"user_id": user_id, "connection_id": connection_id, "user_input": user_input, "prompt": prompt, "image_uuid": image_uuid})
        }

    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
             "body": json.dumps({"error": str(e)})
        }
