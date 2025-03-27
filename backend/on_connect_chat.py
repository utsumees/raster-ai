import json
import boto3
import datetime
import logging
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_secret():

    secret_name = "********"
    region_name = "********"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']
    return json.loads(secret_string)

def connect_db():
    # logger.info("START get_secret")
    # secret = get_secret()
    # logger.info("END get_secret")
    # logger.warn(f"{secret=}")
    conn = psycopg2.connect(
        host="********",
        dbname="********",
        port="****",
        user="********",
        password="********"
    )
    logger.info("SUCCESS: Connection to RDS Aurora instance succeeded")
    return conn

def lambda_handler(event, context):
    try:
        user_id = event["queryStringParameters"]["userid"]
        connection_id = event['requestContext']['connectionId']
        source_ip = event['requestContext']['identity']['sourceIp']
        if "bot" in event["queryStringParameters"]:
            is_bot = True
        else:
            is_bot = False
        connected_at = datetime.datetime.utcnow().isoformat()
        
        conn = connect_db()
        cur = conn.cursor()

        # chats テーブルに初期レコードを追加
        if is_bot:
            print("no commit is executed. because this is bot.")
        else:
            cur.execute(
                """
                UPDATE users SET session_id = %s WHERE user_id = %s
                """,
                (connection_id, user_id)
            )
            conn.commit()
            print("commit finished.", f"{connection_id=}, {user_id=}")

        # domain = event['requestContext']['domainName']
        # stage  = event['requestContext']['stage']
        # apigw = boto3.client(
        #     'apigatewaymanagementapi',
        #     endpoint_url=f"https://{domain}/{stage}"
        # )

        # payload = json.dumps({
        #     'connection_id': connection_id,
        #     'source_ip': source_ip,
        #     'connected_at': connected_at
        # }).encode('utf-8')

        # try:
        #     apigw.post_to_connection(ConnectionId=connection_id, Data=payload)
        # except apigw.exceptions.GoneException:
        #     # 接続が確立する前に呼ばれた場合などは失敗するが無視
        #     pass

        return {
            'statusCode': 200,
            'body': 'Connected.',
        }

    except Exception as e:
        logger.error(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({"status": "failed", "contents": f"Error: {e}"}),
        }
