import json
import boto3
from botocore.exceptions import ClientError
from enum import Enum

class models(Enum):
    claude_3_5 = "anthropic.claude-3-5-sonnet-20241022-v2:0"
    claude_3_7 = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"

modelRegion = '********'
modelId = "anthropic.claude-3-5-sonnet-20241022-v2:0"

def lambda_handler(event, context):
    # TODO implement
    
    require = event['body']
    if type(require) == str:
        require = json.loads(require)
    # print(require.keys())

    client = boto3.client("bedrock-runtime")

    content = []
    if "prompt" in require.keys():
        content.append({"text": require['prompt']})
    if "image" in require.keys():
        content.append({"image": {"source": { "bytes": require['image']}, "format": "png"}})
    # print(content)
    message = {
        "content": content
    }
    # print(message[0].content[1])
    # print(message)
    response = client.converse(
        modelId=models.claude_3_7.value,
        messages=[
            {
                "role": "user",
                "content": content,
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

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({"contents": str(output)}, ensure_ascii=False),
    }


    # return {
    #     'statusCode': 200,
    #     'body': json.dumps(str(body))
    # }