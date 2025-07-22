import boto3
from datetime import datetime, timezone, timedelta
from botocore.exceptions import ClientError
import logging
import os

from logger import send_mattermost_alert

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")
cost_explorer = boto3.client("ce")

COST_THRESHOLD = float(os.environ.get("COST_THRESHOLD", 5.0))
MICRO_MAX_AGE_DAYS = int(os.environ.get("MICRO_MAX_AGE_DAYS", 4))
DEFAULT_MAX_AGE_DAYS = int(os.environ.get("DEFAULT_MAX_AGE_DAYS", 1))
REQUIRED_TAG_KEYS = set(k.strip() for k in os.environ.get("REQUIRED_TAG_KEYS", "Owner,Environment").split(","))


def get_instance_costs():
    today = datetime.utcnow().date()
    start = (today - timedelta(days=3)).isoformat()
    end = today.isoformat()

    try:
        response = cost_explorer.get_cost_and_usage(
            TimePeriod={"Start": start, "End": end},
            Granularity="DAILY",
            Metrics=["UnblendedCost"],
            GroupBy=[{"Type": "DIMENSION", "Key": "RESOURCE_ID"}]
        )
    except ClientError as e:
        logger.error(f"Failed to get cost data: {e}")
        return {}

    cost_map = {}
    for result in response["ResultsByTime"]:
        for group in result["Groups"]:
            resource_id = group["Keys"][0]
            amount = float(group["Metrics"]["UnblendedCost"]["Amount"])
            cost_map[resource_id] = cost_map.get(resource_id, 0) + amount

    return cost_map


def ec2_lifecycle_handler(event, context):
    logger.info("EC2 lifecycle evaluation started.")
    now = datetime.now(timezone.utc)

    try:
        reservations = ec2.describe_instances(
            Filters=[{"Name": "instance-state-name", "Values": ["running"]}]
        )["Reservations"]
    except ClientError as e:
        logger.error(f"Failed to describe instances: {e}")
        return

    costs = get_instance_costs()

    for reservation in reservations:
        for instance in reservation.get("Instances", []):
            instance_id = instance["InstanceId"]
            instance_type = instance["InstanceType"]
            launch_time = instance["LaunchTime"]
            tags = {tag["Key"]: tag["Value"] for tag in instance.get("Tags", [])}
            instance_cost = costs.get(instance_id, 0)

            age = now - launch_time
            allowed_age = timedelta(days=MICRO_MAX_AGE_DAYS if instance_type == "t2.micro" else DEFAULT_MAX_AGE_DAYS)

            logger.info(f"Evaluating {instance_id}: type={instance_type}, age={age}")

            if age > allowed_age:
                send_mattermost_alert(f"Instance {instance_id} has exceeded its max age (age={age}).")

            missing = REQUIRED_TAG_KEYS - set(tags.keys())
            if missing:
                send_mattermost_alert(f"Instance {instance_id} is missing required tags: {missing}")

            if instance_cost > COST_THRESHOLD:
                send_mattermost_alert(f"Instance {instance_id} exceeded cost threshold: ${instance_cost:.2f}")
