# Gateway Endpoints Module

This folder contains a **Terraform module** that provisions AWS VPC Gateway Endpoints for S3 and DynamoDB.

### Resources

This module creates:

- `aws_vpc_endpoint` resources for:
  - S3 (`com.amazonaws.<region>.s3`)
  - DynamoDB (`com.amazonaws.<region>.dynamodb`)

It uses `for_each` over the `gateway_endpoints` map.


| Variable    | Description                                  | Type   |
|-------------|--------------------------------------------|--------|
| `region`    | AWS region string                          | string |
| `config`    | VPC configuration (`vpc_id`, `route_table_id`) | object |
| `tags`      | Map of tags to apply to the endpoints      | map    |



