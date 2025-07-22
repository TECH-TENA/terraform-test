import boto3
import os
import time

def handler(event, context):
    client = boto3.client('logs')
    log_group = os.environ['LOG_GROUP_NAME']
    bucket = os.environ['DESTINATION_BUCKET']

    now = int(time.time() * 1000)
    start_time = now - 24 * 60 * 60 * 1000  # 24 hours ago

    export_task_name = f"export-{int(time.time())}"

    response = client.create_export_task(
        taskName=export_task_name,
        logGroupName=log_group,
        fromTime=start_time,
        to=now,
        destination=bucket,
        destinationPrefix="exported-logs"
    )

    return {"task_id": response['taskId']}
