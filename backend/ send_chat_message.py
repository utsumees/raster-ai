import json
import boto3
import datetime
import logging
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def connect_db():
    conn = psycopg2.connect(
        host="tora-database2-instance-1.cjewo8w02qra.us-west-2.rds.amazonaws.com",
        dbname="postgres",
        port="5432",
        user="postgres",
        password="1W2Jda3DI1*HPgJV#q!>IfoUC$zw"
    )
    logger.info("SUCCESS: Connection to RDS Aurora instance succeeded")
    return conn

def lambda_handler(event, context):
    body = json.loads(event.get('body', '{}'))
    user_id = body.get('userid', '')
    message = body.get('message', '')
    imageurl = body.get('imageurl', '')
    is_stream = body.get('is_stream', False)
    timestamp = datetime.datetime.utcnow()
    connection_id = event['requestContext']['connectionId']
    logger.info(f"Received message: {message}\n  from: {connection_id}")
    if not user_id:
        return {'statusCode': 400, 'body': 'userid cannot be empty'}
    elif not message:
        return {'statusCode': 400, 'body': 'message cannot be empty'}
    # API Gateway Management API のエンドポイントを組み立てる
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']
    endpoint = f"https://{domain_name}/{stage}"
    apigw = boto3.client('apigatewaymanagementapi', endpoint_url=endpoint)

    # RDSにメッセージを保存
    conn = connect_db()
    cur = conn.cursor()
    print("got cursor")
    if is_stream:
        # 最新のチャットを取得(session_idとmessage_idをselect, message_idで降順ソート)
        cur.execute("SELECT user_id, message_id, text, image_url FROM chats WHERE user_id = %s ORDER BY message_id DESC LIMIT 1", (user_id, ))
        result = cur.fetchone()
        print("got fetchone result")
        # 結果をそれぞれの変数にいれる
        if result:
            user_id, message_id, text, image_url = result
            # そのチャットのtextとimageurlを更新
            if imageurl:
                cur.execute("UPDATE chats SET text = %s, imageurl = %s WHERE user_id = %s AND message_id = %s", (text + message, imageurl, user_id, message_id))
            else:
                cur.execute("UPDATE chats SET text = %s WHERE user_id = %s AND message_id = %s", (text + message, user_id, message_id))
        else:
            # チャットがない場合は新規にチャットを作成
            cur.execute("INSERT INTO chats (user_id, post_by, post_at, text, imageurl) VALUES (%s, %s, %s, %s, %s)", (user_id, "human", timestamp, message, imageurl))
    else:
        if imageurl:
            cur.execute("INSERT INTO chats (user_id, post_by, post_at, text, imageurl) VALUES (%s, %s, %s, %s, %s)", (user_id, "human", timestamp, message, imageurl))
        else:
            cur.execute("INSERT INTO chats (user_id, post_by, post_at, text) VALUES (%s, %s, %s, %s)", (user_id, "human", timestamp, message))
    conn.commit()
    print("commit finished")

    # ボットにメッセージを送信
    # cur.execute("SELECT session_id FROM users WHERE user_id = %s", (user_id,))
    # connection_id = cur.fetchone()
    # try:
    #     apigw.post_to_connection(ConnectionId=connection_id, Data=json.dumps({'message': message, 'imageurl': imageurl, 'is_stream': is_stream}))
    #     except Exception as e:
    #         logger.error(f"Error sending message to connection {connection_id}: {e}")
    # NOTE: 代わりに毎回最新の会話履歴をGETさせる

    logger.info("Message sent to all active connections.")

    try:
        # 送信者に対して完了通知を返す
        apigw.post_to_connection(
            ConnectionId=str(connection_id),
            Data=json.dumps({
                'message': message,
                'imageurl': imageurl,
                'status': 'sent'
            }).encode('utf-8')
        )
    except Exception as e:
        logger.error(f"Error sending confirmation to {connection_id}: {e}")
    print("ok. end")
    return {'statusCode': 200, 'body': f'Sent message: {message}'}
