INSTANCE_ID="i-05b29b14739c4b082" 
TAG_KEY="Backup"
TAG_VALUE="true"

for i in {1..3}; do
  AMI_ID=$(aws ec2 create-image \
    --instance-id "$INSTANCE_ID" \
    --name "DemoAMI-$i-$(date +%s)" \
    --description "Demo AMI $i" \
    --no-reboot \
    --query 'ImageId' --output text)
  # Tag AMI with both Backup and InstanceId tags
  aws ec2 create-tags --resources "$AMI_ID" --tags Key=$TAG_KEY,Value=$TAG_VALUE Key=InstanceId,Value=$INSTANCE_ID
  echo "Created and tagged AMI: $AMI_ID"
done
