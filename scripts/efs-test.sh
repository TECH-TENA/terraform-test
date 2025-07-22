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
sudo mount -t nfs4 -o nfsvers=4.1 ${EFS_ID}.efs.${REGION}.amazonaws.com:/ ${MOUNT_POINT}

# Verification
if mountpoint -q ${MOUNT_POINT}; then
  echo "Mount successful on ${MOUNT_POINT}"
else
  echo "Mount failed"
  exit 1
fi

echo "==== Giving full permissions to the mount folder ===="
sudo chmod -R 777 ${MOUNT_POINT}

echo "==== Creating a test file ===="
echo "Hello from $(hostname)" | sudo tee ${MOUNT_POINT}/test-from-$(hostname).txt

echo "==== Adding entry to /etc/fstab for persistent mount ===="
echo "${EFS_ID}.efs.${REGION}.amazonaws.com:/ ${MOUNT_POINT} nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

echo "Script finished. You can check files with: ls -l ${MOUNT_POINT}"
