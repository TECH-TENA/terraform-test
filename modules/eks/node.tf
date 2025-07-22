resource "aws_iam_role" "nodes" {
  name = format("%s-%s-node-group-role", var.tags["environment"], var.tags["project"])

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nodes_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy" "nodes_autoscaler_policy" {
  name = format("%s-%s-node-autoscaler-policy", var.tags["environment"], var.tags["project"])
  role = aws_iam_role.nodes.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_security_group" "nodes" {
  name        = format("%s-%s-node-group-sg", var.tags["environment"], var.tags["project"])
  description = "Security group for EKS node group"
  vpc_id      = var.config.vpc_id

  ingress {
    description = "Allow node-to-node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = format("%s-%s-node-group-sg", var.tags["environment"], var.tags["project"])
  })
}


locals {
  node_groups = {
    blue = {
      enabled     = var.config.blue
      node_color  = var.config.blue_node_color
    },
    green = {
      enabled     = var.config.green
      node_color  = var.config.green_node_color
    }
  }
}

resource "aws_eks_node_group" "main" {
  for_each = {
    for name, config in local.node_groups : name => config
    if config.enabled
  }

  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = format("%s-%s-%s-node-group", var.tags["environment"], var.tags["project"], each.key)
  node_role_arn   = aws_iam_role.nodes.arn

  version        = var.config.eks_version
  subnet_ids     = var.config.private_subnet_ids
  ami_type       = var.config.ami_type
  capacity_type  = var.config.capacity_type
  instance_types = var.config.instance_types
  disk_size      = var.config.disk_size

  scaling_config {
    desired_size = each.value.node_color == each.key ? var.config.desired_node : 0
    min_size     = each.value.node_color == each.key ? var.config.node_min     : 0
    max_size     = each.value.node_color == each.key ? var.config.node_max     : var.config.node_max
  }

  tags = merge(var.tags, {
    Name                                                  = format("%s-%s-%s-node-group", var.tags["environment"], var.tags["project"], each.key)
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks.name}" = var.config.shared_owned
    "k8s.io/cluster-autoscaler/enabled"                   = var.config.enable_cluster_autoscaler
  })
}
