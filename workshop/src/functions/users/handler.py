import json
import os
import uuid
import logging
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

TABLE_NAME = os.environ["USERS_TABLE_NAME"]
PAGE_SIZE = int(os.environ.get("PAGE_SIZE", "20"))

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    method = event["httpMethod"]
    path = event["resource"]
    path_params = event.get("pathParameters") or {}
    query_params = event.get("queryStringParameters") or {}

    try:
        if path == "/users" and method == "GET":
            return list_users(query_params)
        if path == "/users/{userid}" and method == "GET":
            return get_user(path_params["userid"])
        if path == "/users" and method == "POST":
            return create_user(json.loads(event["body"]))
        if path == "/users/{userid}" and method == "PUT":
            return update_user(path_params["userid"], json.loads(event["body"]))
        if path == "/users/{userid}" and method == "DELETE":
            return delete_user(path_params["userid"])
        return response(404, {"message": "Not found"})
    except json.JSONDecodeError:
        return response(400, {"message": "Invalid JSON body"})
    except Exception:
        logger.exception("Unhandled error")
        return response(500, {"message": "Internal server error"})


def list_users(query_params):
    scan_kwargs = {"Limit": PAGE_SIZE}
    if query_params.get("next_token"):
        scan_kwargs["ExclusiveStartKey"] = json.loads(
            query_params["next_token"]
        )
    result = table.scan(**scan_kwargs)
    body = {"users": result.get("Items", [])}
    if "LastEvaluatedKey" in result:
        body["next_token"] = json.dumps(result["LastEvaluatedKey"])
    return response(200, body)


def get_user(userid):
    result = table.get_item(Key={"userid": userid})
    item = result.get("Item")
    if not item:
        return response(404, {"message": "User not found"})
    return response(200, item)


def create_user(body):
    body.pop("userid", None)
    item = {
        "userid": str(uuid.uuid4()),
        "created_at": datetime.now(timezone.utc).isoformat(),
        **body,
    }
    table.put_item(Item=item)
    return response(201, item)


def update_user(userid, body):
    result = table.get_item(Key={"userid": userid})
    if not result.get("Item"):
        return response(404, {"message": "User not found"})

    body.pop("userid", None)
    body["updated_at"] = datetime.now(timezone.utc).isoformat()

    expr_names = {}
    expr_values = {}
    update_parts = []
    for i, (k, v) in enumerate(body.items()):
        expr_names[f"#k{i}"] = k
        expr_values[f":v{i}"] = v
        update_parts.append(f"#k{i} = :v{i}")

    table.update_item(
        Key={"userid": userid},
        UpdateExpression="SET " + ", ".join(update_parts),
        ExpressionAttributeNames=expr_names,
        ExpressionAttributeValues=expr_values,
    )
    return response(200, {"userid": userid, **body})


def delete_user(userid):
    table.delete_item(Key={"userid": userid})
    return response(200, {"message": "User deleted"})


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, default=str),
    }
