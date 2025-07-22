# AWS RDS Resource Launcher

This directory defines the Terraform resource block that calls the reusable RDS module for PostgreSQL provisioning.

## Project Structure

modules/aws-rds
└── postgresql-instance
    ├── main.tf
    ├── monitoring.tf
    ├── outputs.tf
    ├── README.md
    └── variables.tf
resources/aws-rds
├── main.tf
├── README.md

3 directories, 7 files