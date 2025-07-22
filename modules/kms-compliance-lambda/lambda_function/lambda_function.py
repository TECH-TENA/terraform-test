import boto3
import json
import os
import uuid
import requests
import logging
from datetime import datetime, timezone

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
kms = boto3.client('kms')
ec2 = boto3.client('ec2')
dynamodb = boto3.resource('dynamodb')

# DynamoDB table name from environment variable (or default)
DDB_TABLE = os.environ.get("DYNAMODB_TABLE_NAME", "KMSComplianceLogs")
ddb_table = dynamodb.Table(DDB_TABLE)

# Helper function to send notification to Mattermost
def send_mattermost_notification(message):
    try:
        webhook_url = os.environ['MM_WEBHOOK_URL']
        payload = {"text": message}
        response = requests.post(webhook_url, json=payload)
        if response.status_code == 200:
            logger.info("Successfully sent notification to Mattermost")
        else:
            logger.error(f"Failed to send notification to Mattermost: {response.status_code} - {response.text}")
    except Exception as e:
        logger.error(f"Error sending Mattermost notification: {str(e)}")

def lambda_handler(event, context):
    # Retrieve all customer-managed KMS keys using paginator
    paginator = kms.get_paginator('list_keys')
    for page in paginator.paginate():
        kms_keys = page.get('Keys', [])
        for key in kms_keys:
            key_id = key['KeyId']
            key_metadata = kms.describe_key(KeyId=key_id)['KeyMetadata']

            # Skip AWS-managed keys
            if key_metadata.get('KeyManager') != 'CUSTOMER':
                continue

            # Basic key metadata
            key_state = key_metadata['KeyState']
            key_enabled = key_metadata['Enabled']
            key_creation_date = key_metadata['CreationDate']
            key_deletion_date = key_metadata.get('DeletionDate')
            days_to_deletion = (
                (key_deletion_date - datetime.now(timezone.utc)).days
                if key_deletion_date else None
            )

            # Get key tags
            key_tags = kms.list_resource_tags(KeyId=key_id).get('Tags', [])

            # Get aliases
            aliases_resp = kms.list_aliases(KeyId=key_id)
            alias_names = [a['AliasName'] for a in aliases_resp.get('Aliases', [])]

            # Check and possibly enable rotation
            try:
                rotation_status = kms.get_key_rotation_status(KeyId=key_id)
                rotation_enabled = rotation_status.get('KeyRotationEnabled', False)
            except Exception:
                rotation_enabled = False

            if not rotation_enabled:
                try:
                    kms.enable_key_rotation(KeyId=key_id)
                    rotation_action = "Enabled"
                except Exception as e:
                    rotation_action = f"Failed to enable: {str(e)}"
            else:
                rotation_action = "Already enabled"

            # Find all EBS volumes encrypted by this key using paginator
            ebs_volumes = []
            volume_paginator = ec2.get_paginator('describe_volumes')
            for vol_page in volume_paginator.paginate(Filters=[{"Name": "encrypted", "Values": ["true"]}]):
                ec2_volumes = vol_page.get("Volumes", [])
                for volume in ec2_volumes:
                    if volume.get("KmsKeyId") and key_id in volume["KmsKeyId"]:
                        ebs_volumes.append(volume["VolumeId"])

            # Write compliance log to DynamoDB
            ddb_table.put_item(Item={
                "compliance_check_id": str(uuid.uuid4()),
                "KMSKeyId": key_id,
                "LogTimestamp": datetime.utcnow().isoformat(),
                "KeyAliases": alias_names,
                "KeyState": key_state,
                "AutoRotationEnabled": rotation_enabled,
                "RotationActionTaken": rotation_action,
                "KeyCreationDate": str(key_creation_date),
                "ScheduledDeletionDate": str(key_deletion_date) if key_deletion_date else None,
                "DaysUntilDeletion": days_to_deletion,
                "KeyTags": key_tags,
                "EBSVolumesEncrypted": ebs_volumes,
            })

            # Send notification to Mattermost
            message = (
                f"KMS Compliance Check:\n"
                f"- Key ID: {key_id}\n"
                f"- Aliases: {', '.join(alias_names) if alias_names else 'None'}\n"
                f"- State: {key_state}\n"
                f"- Rotation: {rotation_action}\n"
                f"- Encrypted EBS Volumes: {', '.join(ebs_volumes) if ebs_volumes else 'None'}"
            )
            send_mattermost_notification(message)

    return {
        "statusCode": 200,
        "body": json.dumps("KMS compliance check completed.")
    }
