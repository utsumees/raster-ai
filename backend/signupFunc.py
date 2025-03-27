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
    print(event)
    body = event["body"]
    if type(body) == str:
        body = json.loads(body)
    print(body.keys())
    print(body["user_id"])
    email = body["user_id"]
    password = body["password"]

    statusCode = 400
    result = "something happened"
    if not email or not password:
        result = "No email or passward provided"
        statusCode = 400
    
    conn = None
    try:
        conn = connect_db()
        cur = conn.cursor()

        # ① email の存在チェック
        cur.execute("SELECT * FROM users WHERE user_id = %s", (email,))
        if cur.fetchone():
            # return _response(409, {"error": "Email already registered"})
            result = "Email already registered"
            statusCode = 409
            raise Exception(result)

        # ② 新規ユーザ登録
        cur.execute(
            "INSERT INTO users (user_id, password) VALUES (%s, %s)",
            (email, password)
        )
        conn.commit()
        # return _response(201, {"message": "User created"})
        result = "User created"
        statusCode = 201
    except Exception as e:
        print(e)


    finally:
        if conn:
            conn.close()

    return {
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'statusCode': statusCode,
        'body': json.dumps({"result": result})
    }