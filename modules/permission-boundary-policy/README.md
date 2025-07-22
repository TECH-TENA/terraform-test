# core-webforx-permissions-boundary

This Terraform module defines an IAM **Permissions Boundary Policy** named `core-webforx-permissions-boundary` for controlling IAM role creation and usage in the `webforx` environment. It enforces security, naming standards, and resource control for IAM users and automation processes within an AWS account.

---

## Purpose

The permissions boundary serves as a **guardrail** that limits what actions an IAM role can perform—even if broader permissions are granted through identity-based policies. It ensures:

- IAM roles follow naming conventions (`service-*`)
- Networking and sensitive infrastructure is protected
- Core S3 resources and IAM policies are immutable
- Only approved AWS services can be used

---

## Key Features

### Allowed Service Actions

Grants access to a curated list of AWS services (e.g., EC2, S3, RDS, Lambda, IAM read-only) for general usage. These services support most application and platform needs.

---

### IAM Role Control

#### Enforced Naming Convention
Only IAM roles prefixed with `service-` can be created or managed.

#### Mandatory Permissions Boundary
All roles created or managed must attach this exact policy as their `PermissionsBoundary`.

#### Scoped Policy Management
Users can only:
- Attach/Detach managed policies
- Modify inline policies
- Update or delete roles
If the target role is named `service-*` and uses this boundary.

---

### Denied Actions

#### Networking Restrictions
Prevents creation or modification of core network resources:
- Internet/NAT Gateways
- VPNs and Customer Gateways
- VPCs and VPC Endpoints

#### S3 Restrictions
Blocks destructive actions (`Put*`, `Delete*`, `Object*`) on S3 buckets named with the prefix `core-`.

#### IAM Boundary Protection
Prevents tampering with this policy itself (`core-webforx-*`), such as:
- Deleting the policy or versions
- Creating new versions
- Changing the default version

#### SNS Protocol Guard
Denies SNS subscriptions unless the protocol is `email`, `lambda`, or `sqs`.

---

## Usage

### Terraform Example

```hcl
module "permissions_boundary" {
  source = "../../modules/permissions-boundary-policy"

  # The policy is created in this module
}

resource "aws_iam_role" "example" {
  name = "service-my-app"

  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
  permissions_boundary  = module.permissions_boundary.policy_arn

  # other role settings ...
}
```

## Outputs
	
Name: webforx_policy_arn, 

Description: ARN of the created permissions boundary

## Notes
This boundary does not grant permissions by itself. You must still attach identity-based policies to roles.

The boundary limits what the identity policy can do.

It's intended to be used in environments where IAM users or automation should be constrained for safety.


