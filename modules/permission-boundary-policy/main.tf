data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "webforx_permissions_boundary" {
  name        = "core-webforx-permissions-boundary"
  description = "WebForx Permissions Boundary IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowApprovedServiceActions",
        Effect = "Allow",
        Action = [
          "acm:*",
          "apigateway:*",
          "application-autoscaling:*",
          "athena:*",
          "autoscaling:*",
          "autoscaling-plans:*",
          "backup:*",
          "backup-storage:*",
          "cloudtrail:*",
          "cloudwatch:*",
          "codeartifact:*",
          "codebuild:*",
          "codecommit:*",
          "codedeploy:*",
          "codepipeline:*",
          "config:*",
          "dlm:*",
          "ds:DescribeDirectories",
          "dynamodb:*",
          "ec2:*",
          "ec2-instance-connect:SendSSHPublicKey",
          "ec2messages:*",
          "ecr:*",
          "ecs:*",
          "eks:*",
          "es:*",
          "elasticache:*",
          "elasticfilesystem:*",
          "elasticloadbalancing:*",
          "elasticmapreduce:*",
          "events:*",
          "firehose:*",
          "glacier:*",
          "glue:*",
          "guardduty:*",
          "iam:Get*",
          "iam:List*",
          "iam:CreateOpenIDConnectProvider",
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UnTagOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:DeleteOpenID*",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:Tag*",
          "iam:GenerateServiceLastAccessedDetails",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "imagebuilder:*",
          "inspector:*",
          "kinesis:*",
          "kms:*",
          "lambda:*",
          "rds:*",
          "redshift:*",
          "route53:*",
          "route53resolver:*",
          "s3:*",
          "sagemaker:*",
          "sdb:*",
          "secretsmanager:*",
          "securityhub:*",
          "sqs:*",
          "sms:*",
          "sns:*",
          "ssm:*",
          "ssmmessages:*",
          "states:*",
          "sts:DecodeAuthorizationMessage",
          "sts:AssumeRole",
          "support:*",
          "synthetics:*",
          "tag:*",
          "textract:*"
        ],
        Resource = "*"
      },
      {
        Sid    = "IAMRoleAndPolicyControl",
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:PutRolePermissionsBoundary"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-*",
        Condition = {
          "StringEquals": {
            "iam:PermissionsBoundary": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/core-webforx-permissions-boundary"
          }
        }
      },
      {
        Sid    = "AllowIAMPolicyUpdatesOnScopedRoles",
        Effect = "Allow",
        Action = [
          "iam:AttachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-*",
        Condition = {
          "StringEquals": {
            "iam:PermissionsBoundary": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/core-webforx-permissions-boundary"
          }
        }
      },
      {
        Sid    = "IAMRoleLifecycle",
        Effect = "Allow",
        Action = [
          "iam:DeleteRole",
          "iam:PassRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRoleDescription",
          "iam:TagRole"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-*"
      },
      {
        Sid    = "IAMPolicyDenyEditsToCoreBoundary",
        Effect = "Deny",
        Action = [
          "iam:Delete*PermissionsBoundary",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ],
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/core-webforx-*"
      },
      {
        Sid    = "DenyNetworkingResourceCreation",
        Effect = "Deny",
        Action = [
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:CreateCustomerGateway",
          "ec2:CreateVpnConnection",
          "ec2:CreateVpnGateway",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:EnableVpcClassicLink",
          "ec2:DisableVpcClassicLink",
          "ec2:CreateVpcEndpoint"
        ],
        Resource = "*"
      },
      {
        Sid    = "DenySensitiveS3Modifications",
        Effect = "Deny",
        Action = [
          "s3:Delete*",
          "s3:Put*",
          "s3:Object*"
        ],
        Resource = "arn:aws:s3:::core-*"
      },
      {
        Sid    = "SNSSubscriptionProtocolControl",
        Effect = "Deny",
        Action = ["sns:Subscribe"],
        Resource = "*",
        Condition = {
          "StringNotEquals": {
            "SNS:Protocol": ["email", "lambda", "sqs"]
          }
        }
      }
    ]
  })
}


