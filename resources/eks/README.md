# Terraform AWS EKS Module

This module provisions a reusable, scalable Amazon EKS cluster in an AWS sandbox environment. It includes EKS control plane, managed node groups, IAM roles and policies, networking integration, and optional default storage class provisioning.

## Features

- EKS control plane creation with customizable Kubernetes version
- Blue-green managed node group deployment
- IAM roles and policy attachments for both cluster and nodes
- Integration with existing VPC and subnets
