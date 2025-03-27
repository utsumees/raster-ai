import json
import boto3

bedrock = boto3.client("bedrock-runtime")

def lambda_handler(event, context):

    content = [
            {
                "type": "image",
                "source": {
                    "type": "url",
                    "url": "https://upload.wikimedia.org/wikipedia/commons/a/a7/Camponotus_flavomarginatus_ant.jpg",
                },
            },
            {   "type": "text",
                "text": "ほげ"
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
    response = bedrock.invoke_model(
        modelId="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
        contentType="application/json",
        accept="application/json",
        body=body
        # additionalModelRequestFields={
        #     "thinking": {"type": "enabled", "budget_tokens": 1024},
        # },
    )
    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
