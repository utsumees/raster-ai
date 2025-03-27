import json
import boto3
import psycopg2
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_secret():

    secret_name = "rds!cluster-7ed55f95-31fa-4f79-b3db-7339f2f5b686"
    region_name = "us-west-2"

    # Create a Secrets Manager client
    logger.info("Create boto3 session")
    session = boto3.session.Session()
    logger.info("Create boto3 client")
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    logger.info("Got client")
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        logger.info("Got secret")
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
    body = json.loads(event.get("body", "{}"))
    conn = connect_db()
    cur = conn.cursor()
    if body and "sql" in body:
        cur.execute(body["sql"])
        result = cur.fetchone()
    else:
        result = "No SQL provided"
    
    return {
        'statusCode': 200,
        'body': json.dumps({"result": result})
    }
