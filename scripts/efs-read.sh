#!/bin/bash

# Variables to modify according to your setup
EFS_ID="fs-0ca86204fe8b9187e"     # <-- Replace with your EFS ID
REGION="us-east-1"                # <-- Replace with your region
MOUNT_POINT="/mnt/efs"

echo "==== Updating package list and installing nfs-common ===="
sudo apt update -y
sudo apt install -y nfs-common

echo "==== Creating mount directory ===="
sudo mkdir -p ${MOUNT_POINT}

echo "==== Mounting EFS ===="
# Capture the output and exit code of the mount command
MOUNT_OUTPUT=$(sudo mount -t nfs4 -o nfsvers=4.1 ${EFS_ID}.efs.${REGION}.amazonaws.com:/ ${MOUNT_POINT} 2>&1)
MOUNT_EXIT_CODE=$?

if [ $MOUNT_EXIT_CODE -eq 0 ]; then
  echo "Mount successful on ${MOUNT_POINT}"
else
  echo "Mount failed"
  echo "------ Error output ------"
  echo "$MOUNT_OUTPUT"

  # Detect common errors related to security group/network issues
  if echo "$MOUNT_OUTPUT" | grep -qiE "No route to host|Connection timed out|Permission denied"; then
    echo "This instance (e.g. your bastion) is likely not authorized by the EFS security group."
    echo "Please ensure the EFS security group allows inbound NFS (TCP 2049) from this instance's security group."
  fi

  exit 1
fi

echo "==== Reading existing test files ===="
ls -l ${MOUNT_POINT}
echo "----- Content of test files -----"
cat ${MOUNT_POINT}/test-from-* 2>/dev/null

echo "==== Adding entry to /etc/fstab for persistent mount ===="
echo "${EFS_ID}.efs.${REGION}.amazonaws.com:/ ${MOUNT_POINT} nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

echo "Script finished."
