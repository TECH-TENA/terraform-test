# Terraform Infrastructure as Code Repository

## Overview


## Structure


## Terraform installation
The terraform version for this project is `1.10.5`

1. Install on Linux
```sh
#!/bin/bash

TERRAFORM_VERSION="1.10.5"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

INSTALL_DIR="/usr/local/bin"
echo "Downloading Terraform ${TERRAFORM_VERSION}..."
curl -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip ${DOWNLOAD_URL}
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform ${INSTALL_DIR}/terraform
sudo chmod +x ${INSTALL_DIR}/terraform
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
echo "Terraform installation complete."
terraform version
```

2. Installation on Mac
```sh
#!/bin/bash

TERRAFORM_VERSION="1.10.5"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip"
INSTALL_DIR="/usr/local/bin"

curl -o terraform_${TERRAFORM_VERSION}_darwin_amd64.zip ${DOWNLOAD_URL}
unzip terraform_${TERRAFORM_VERSION}_darwin_amd64.zip
sudo mv terraform ${INSTALL_DIR}/terraform
sudo chmod +x ${INSTALL_DIR}/terraform
rm terraform_${TERRAFORM_VERSION}_darwin_amd64.zip

echo "Terraform installation complete."
terraform version
```

3. Windows installation
- [Click here to download terraform for windows](https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_windows_amd64.zip)

```s
# Installing Terraform on Windows

This guide provides step-by-step instructions on how to install Terraform 1.10.5 on Windows.

## Prerequisites
- Windows 7 or later.
- Administrative access to your system.
- An archive utility that can handle `.zip` files, such as WinRAR, 7-Zip, or the built-in Windows extractor.

## Installation Steps

### Step 1: Download the Terraform Zip File
1. Navigate to [Terraform's official download](https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_windows_amd64.zip).

### Step 2: Extract the Terraform Executable
1. Locate the downloaded `.zip` file, usually in your `Downloads` folder.
2. Right-click the file and select "Extract All..." or use your preferred archive utility.
3. Choose a destination for the extracted files. It's recommended to use a path without spaces, such as `C:\Tools\Terraform`.

### Step 3: Update System PATH
1. Search for "Environment Variables" in your Start menu and select "Edit the system environment variables" (System Properties window).
2. In the System Properties window, click on the "Environment Variables" button.
3. Under "System variables", scroll down and find the `Path` variable, then click "Edit...".
4. Click "New" and add the path where you extracted Terraform (e.g., `C:\Tools\Terraform`).
5. Click "OK" to close all dialogs and save your changes.

### Step 4: Verify Installation
1. Open a new Command Prompt window.
2. Type `terraform -version` and press Enter.
3. Ensure that the command outputs "Terraform v1.10.5", confirming that Terraform is correctly installed.
```

## Project paths in s3
- At the root of the bucket, we should provide directory that represent the project name and create another directory in those to store the state file
```t
backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "webforx/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }

backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "connect/db/mariadb/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }

backend "s3" {
    bucket         = "development-webforx-sandbox-tf-state"
    key            = "connect/ec2/bastion/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "development-webforx-sandbox-tf-state-lock"
  }
```

## Example webfox s3 backend set up 
![alt text](/images/s3-backend.png)