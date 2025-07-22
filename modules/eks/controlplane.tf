resource "aws_iam_role" "eks_cluster" {
  name = format("%s-%s-control-plane-role", var.tags["environment"], var.tags["project"])

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_security_group" "eks_control_plane" {
  name        = format("%s-%s-control-plane-sg", var.tags["environment"], var.tags["project"])
  description = "EKS control plane security group"
  vpc_id      = var.config.vpc_id

  ingress {
    description = "Allow nodes to communicate with control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = format("%s-%s-control-plane-sg", var.tags["environment"], var.tags["project"])
  })
}

resource "aws_eks_cluster" "eks" {
  name     = format("%s-%s", var.tags["environment"], var.tags["project"])
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.config.eks_version

  vpc_config {
    subnet_ids              = var.config.public_subnet_ids
    endpoint_private_access = var.config.endpoint_private_access
    endpoint_public_access  = var.config.endpoint_public_access
    security_group_ids      = [aws_security_group.eks_control_plane.id]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
