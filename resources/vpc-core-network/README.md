# VPC Core Network Module (Terraform)

This Terraform module provisions the core networking infrastructure for an AWS environment, including a VPC, public and private subnets, route tables, and an internet gateway. It is designed for flexible extension with optional components such as NAT Gateways and VPC peering.

---

## Key Objectives

- Create a VPC with:
  - 3 public subnets
  - 3 private subnets
- Set up route tables for public subnet routing
- Attach an Internet Gateway to enable public access
- NAT Gateway and VPC peering are excluded by default
- NACLs are open to all traffic to allow unrestricted access for initial testing
-  Default VPC Deletion
Set delete_default_vpc = true (environment/webforx.yaml) to remove the default VPC and its resources before creating the custom VPC. By default, it's false to prevent accidental deletion. The logic is safe and skips deletion if the default VPC doesn't exist.

## Module Structure

vpc-core-network/
├── gateway-endpoint.tf # Optional S3 & DynamoDB VPC endpoints
├── internet-gateway.tf 
├── nacl.tf 
├── output.tf # Outputs from the module
├── remove-default-vpc.tf 
├── route-table.tf 
├── variables.tf 
├── vpc.tf 



**Outputs**
- vpc_id
- public_subnet_ids
- private_subnet_ids
- internet_gateway_id
- route_table_ids

**Notes**
NACLs are open by default for testing. Restrict them before production deployment.

NAT Gateway and VPC Peering are not included in this version but can be added later.

Default VPC deletion is set false for initial testing. It is typically removed to ensure compliance and a clean environment.