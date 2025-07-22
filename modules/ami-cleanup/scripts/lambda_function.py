"""
AMI Cleanup Lambda Function

Deletes all but the latest Amazon Machine Image (AMI) per EC2 instance, and their associated EBS snapshots.
Sends notifications to SNS and Mattermost, and logs the result to AWS SSM Parameter Store.

Environment Variables Required:
- AMI_TAG_KEY: Tag key to identify AMIs (default: "Backup")
- AMI_TAG_VALUE_PREFIX: Tag value prefix (default: "true")
- SNS_TOPIC_ARN: ARN of the SNS topic for notifications (optional)
- MATTERMOST_WEBHOOK_URL: Mattermost webhook URL (optional)

Expected IAM Permissions:
- ec2:DescribeImages, ec2:DeregisterImage, ec2:DeleteSnapshot
- sns:Publish (to the SNS topic)
- ssm:PutParameter (to the /ami-cleanup/last-run SSM parameter)
"""

import boto3
import os
from datetime import datetime, timezone
import traceback
import requests

ec2 = boto3.client('ec2')
account_id = boto3.client('sts').get_caller_identity().get('Account')
sns = boto3.client('sns')
ssm = boto3.client('ssm')

sns_topic_arn = os.environ.get('SNS_TOPIC_ARN', '')
ami_tag_key = os.environ.get('AMI_TAG_KEY', 'Backup')
ami_tag_value_prefix = os.environ.get('AMI_TAG_VALUE_PREFIX', 'true')

# --- Mattermost ---
def send_mattermost_notification(subject, message):
    webhook_url = os.environ.get('MATTERMOST_WEBHOOK_URL', '')
    if webhook_url:
        try:
            payload = {"text": f"**{subject}**\n{message}"}
            response = requests.post(webhook_url, json=payload, timeout=10)
            print(f"Mattermost response: {response.status_code} {response.text}")
        except Exception as e:
            print(f"Failed to send Mattermost notification: {e}")
    else:
        print("MATTERMOST_WEBHOOK_URL not set, skipping Mattermost notification.")

# --- SNS Notification ---
def send_notification(subject, message):
    print(f"Sending SNS notification: {subject}")
    if sns_topic_arn:
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
    else:
        print("SNS_TOPIC_ARN not set, skipping SNS notification.")

# --- SSM Logging ---
def log_to_ssm(parameter_name, value):
    print(f"Writing to SSM: {parameter_name} -> {value}")
    try:
        ssm.put_parameter(
            Name=parameter_name,
            Value=value,
            Type='String',
            Overwrite=True
        )
    except Exception as e:
        print(f"Failed to write to SSM: {e}")

# --- Lambda Handler ---
def lambda_handler(event, context):
    run_time = datetime.now(timezone.utc).isoformat()
    summary_lines = []

    try:
        images = ec2.describe_images(
            Owners=[account_id],
            Filters=[{'Name': f'tag:{ami_tag_key}', 'Values': [ami_tag_value_prefix]}]
        )['Images']

        images_by_instance = {}
        for image in images:
            instance_id = next((tag['Value'] for tag in image.get('Tags', []) if tag['Key'] == 'InstanceId'), None)
            if not instance_id:
                continue
            images_by_instance.setdefault(instance_id, []).append(image)

        total_deleted = 0
        total_snapshots = 0
        for instance_id, imgs in images_by_instance.items():
            imgs.sort(key=lambda x: x['CreationDate'], reverse=True)
            for old_image in imgs[1:]:
                ami_id = old_image['ImageId']
                print(f"Deleting AMI {ami_id} for instance {instance_id}")
                summary_lines.append(f"Deleted AMI: {ami_id} (Instance: {instance_id})")
                ec2.deregister_image(ImageId=ami_id)
                for mapping in old_image.get('BlockDeviceMappings', []):
                    snapshot_id = mapping.get('Ebs', {}).get('SnapshotId')
                    if snapshot_id:
                        try:
                            ec2.delete_snapshot(SnapshotId=snapshot_id)
                            print(f"Deleted snapshot {snapshot_id}")
                            summary_lines.append(f"  Deleted snapshot: {snapshot_id}")
                            total_snapshots += 1
                        except Exception as e:
                            error_msg = f"Failed to delete snapshot {snapshot_id}: {e}"
                            print(error_msg)
                            send_notification("AMI Cleanup Warning: Snapshot Deletion Failed", error_msg)
                            send_mattermost_notification("AMI Cleanup Warning: Snapshot Deletion Failed", error_msg)
                total_deleted += 1

        if total_deleted > 0:
            subject = "AMI Cleanup Success"
            message = (
                f"AMI cleanup completed at {run_time}.\n"
                f"Total AMIs deleted: {total_deleted}\n"
                f"Total snapshots deleted: {total_snapshots}\n\n"
                + "\n".join(summary_lines)
            )
        else:
            subject = "AMI Cleanup Info"
            message = (
                f"AMI cleanup ran at {run_time}.\n"
                "No AMIs were deleted (no old AMIs matched the filter or only latest present).\n"
            )

        send_notification(subject, message)
        send_mattermost_notification(subject, message)
        log_to_ssm('/ami-cleanup/last-run', f"{subject} | {message}")

    except Exception as e:
        error_message = f"AMI cleanup failed at {run_time}: {e}\nTraceback:\n{traceback.format_exc()}"
        print(error_message)
        send_notification("AMI Cleanup Failure", error_message)
        send_mattermost_notification("AMI Cleanup Failure", error_message)
        log_to_ssm('/ami-cleanup/last-run', error_message)
        raise
