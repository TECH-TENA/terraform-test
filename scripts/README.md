## Scripts for deployment and maintenance.

- Mounting Amazon EFS on an EC2 Instance (Ubuntu)

This script automates the process of mounting an Amazon Elastic File System (EFS) to an EC2 instance running Ubuntu. It's designed to be reusable and easily customizable for your environment.
#name of the script EFS-test.sh. This can be change.
#!/bin/bash

# Variables to modify according to your setup
EFS_ID="fs-xxxxxxxxxxxxxxxxx"     # <-- Replace with your EFS ID
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

- How to Use
Update the variables at the top of the script:
EFS_ID: your actual EFS file system ID
REGION: your AWS region
MOUNT_POINT: target mount path (default is /mnt/efs)

- Make the script executable:(Optional)
chmod +x name-of-file.sh    

- What This Script Does
Step	Description
    Installs the nfs-common package required for EFS
    Creates the mount directory
    Mounts the EFS volume using NFSv4.1
    Verifies the mount was successful
    Sets open permissions (for testing/demo purposes)
    Creates a test file for verification
    Appends an /etc/fstab entry to make the mount persistent on reboot

- Notes
This script is intended for Ubuntu-based EC2 instances.
The open permission (chmod -R 777) is suitable for testing but not recommended for production. Adjust as needed.
Make sure your EC2 instance is in the same VPC and subnet with EFS access (via mount target).
Ensure security groups allow NFS (port 2049) traffic between the EC2 and the EFS mount target.

NB: EFS-read has the same structure but it just read the file using cat linux command.