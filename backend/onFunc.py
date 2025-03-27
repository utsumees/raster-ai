import json
import boto3
import psycopg2
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

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
    body = event["body"]
    if type(body) == str:
        body = json.loads(body)
    conn = connect_db()
    cur = conn.cursor()
    print(body)
    print(body.keys())

    try:
        # bodyのチェック
        if body and "user_id" in body and "password" in body:
            # SQL文を組み立て
            sql = f"SELECT password FROM users WHERE user_id = '{body['user_id']}'"
            # SQLを実行
            # print("done here")
            cur.execute(sql)
            row = cur.fetchone()
            print(type(row))

            # パスワード一致チェック
            if row and row[0] == body["password"]:
                result = "OK"
                statusCode = 200
            else:
                result = "NG"
                statusCode = 401
        else:
            result = "No SQL provided"
            statusCode = 400

    except Exception as e:
        # 何らかのエラーが発生した場合の処理
        result = f"Error occurred {e}"
        print(result)
        statusCode = 500
    
    return {
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'statusCode': statusCode,
        'body': json.dumps({"result": result})
    }
