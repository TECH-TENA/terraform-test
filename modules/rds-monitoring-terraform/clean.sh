#!/bin/bash

echo "Cleaning Terraform generated files..."

# Remove hidden .terraform directory
rm -rf .terraform

# Remove lock file
rm -f .terraform.lock.hcl

# Remove state files
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# Optionally: Remove plan files if you have them
rm -f *.tfplan

echo "Clean-up complete!"
