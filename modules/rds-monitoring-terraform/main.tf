data "aws_caller_identity" "current" {}

resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      },
      Action = "sts:AssumeRole",
      Condition = {
        StringLike = {
          "aws:SourceArn" = "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:db:${var.db_identifier}"
        },
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "null_resource" "enable_rds_monitoring" {
  triggers = {
    db_identifier = var.db_identifier
    region        = var.region
  }

provisioner "local-exec" {
  command = <<EOT
    echo "Waiting 60 seconds to ensure IAM role is propagated..."
    sleep 60
    aws rds modify-db-instance \
      --db-instance-identifier ${var.db_identifier} \
      --monitoring-interval 60 \
      --monitoring-role-arn ${aws_iam_role.rds_monitoring.arn} \
      --enable-performance-insights \
      --performance-insights-retention-period 7 \
      --apply-immediately
  EOT
}

  depends_on = [
    aws_iam_role.rds_monitoring,
    aws_iam_role_policy_attachment.rds_monitoring_attach
  ]
}
