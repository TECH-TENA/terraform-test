#!/bin/bash

echo "🧹 Cleaning Terraform-generated files..."

# Delete hidden Terraform directories and lock file
rm -rf .terraform
rm -f .terraform.lock.hcl

# Delete Terraform state files
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# Delete any plan output files
rm -f *.tfplan*
rm -f *.plan*

echo "✅ Terraform artifacts cleaned."
