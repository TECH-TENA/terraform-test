# Gateway Endpoints Resource

This folder contains the Terraform configuration that **deploys the gateway endpoints** using the reusable module in `../../modules/gateway-endpoints`.

### Overview

- Loads environment configurations from:
  - `../../environments/region.yaml`
  - `../../environments/webforx.yaml`

- Configures the AWS provider using the selected region.

- Calls the `gateway-endpoints` module to create:
  - S3 Gateway Endpoint
  - DynamoDB Gateway Endpoint

### Usage

To deploy:

```bash
terraform init
terraform plan
terraform apply
```
