import json
import boto3
import logging
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def connect_db():
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
    user_id = event["queryStringParameters"]["userid"]
    conn = connect_db()
    cur = conn.cursor()
    cur.execute("SELECT session_id FROM users WHERE user_id = %s", (user_id,))
    session_id = cur.fetchone()[0]
    cur.close()
    return {
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'statusCode': 200,
        'body': session_id
    }
