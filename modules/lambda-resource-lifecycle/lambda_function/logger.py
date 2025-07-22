import logging
import json
import os
import urllib3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

http = urllib3.PoolManager()
MATTERMOST_WEBHOOK_URL = os.environ.get("MATTERMOST_WEBHOOK_URL")


def send_mattermost_alert(message, title="EC2 Lifecycle Alert"):
    if not MATTERMOST_WEBHOOK_URL:
        logger.warning("Mattermost webhook not set.")
        return

    payload = {
        "text": f"#### {title}\n{message}"
    }

    try:
        response = http.request(
            "POST",
            MATTERMOST_WEBHOOK_URL,
            body=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        logger.info(f"Mattermost alert sent. Status: {response.status}")
    except Exception as e:
        logger.error(f"Failed to send Mattermost alert: {e}")


def resource_logger_handler(event, context):
    logger.info("Resource creation logging started.")
    logger.info(json.dumps(event))

    detail = event.get("detail", {})
    event_name = detail.get("eventName")
    user = detail.get("userIdentity", {}).get("arn", "unknown")
    time = detail.get("eventTime", "unknown")

    if event_name == "CreateBucket":
        bucket_name = detail.get("requestParameters", {}).get("bucketName", "unknown")
        logger.info(f"S3 Bucket Created: {bucket_name} by {user} at {time}")

    elif event_name == "CreateSecret":
        secret_name = detail.get("requestParameters", {}).get("name", "unknown")
        logger.info(f"Secret Created: {secret_name} by {user} at {time}")

    else:
        logger.warning(f"Unhandled event type: {event_name}")
