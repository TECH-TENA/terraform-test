# Enhanced Monitoring and Performance Insights on RDS

## Setup Instructions

### Enable RDS Monitoring and Metrics Collection with Terraform

This Terraform configuration will:
- Create an IAM role for RDS Enhanced Monitoring.
- Attach the required AWS-managed policy.
- Use the AWS CLI to enable Enhanced Monitoring and Performance Insights.
- Leave all other configurations of the existing RDS instance unchanged.

#### Prerequisites
- AWS CLI installed and configured with sufficient permissions to update RDS.
- Terraform installed.

#### 1. Configure your RDS parameters

Update database identifier in 'environments/webforx.yaml':

#### 2. Initialize and apply the Terraform configuration
```bash
terraform init
terraform apply
```

#### 3. Verify Enhanced Monitoring is enabled

Run the following AWS CLI command:
```bash
aws rds describe-db-instances \
  --db-instance-identifier <your-database-name> \
  --query "DBInstances[0].MonitoringInterval"
```

If the result is 0, Enhanced Monitoring is disabled.

If it returns 1, 5, 10, 15, etc., Enhanced Monitoring is enabled with the interval shown in seconds.

