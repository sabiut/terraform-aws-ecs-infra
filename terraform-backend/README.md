# Terraform Backend Setup

This directory contains the Terraform configuration to create the S3 bucket and DynamoDB table required for storing Terraform state remotely.

## Purpose

This setup creates the backend infrastructure needed for:
- S3 bucket for storing Terraform state files
- DynamoDB table for state locking and consistency

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version >= 1.0)
3. IAM permissions to create S3 bucket and DynamoDB table

## Deployment Instructions

### 1. Configure Variables

Copy and edit the variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
aws_region        = "ap-southeast-2"
state_bucket_name = "your-project-terraform-state-bucket"
lock_table_name   = "terraform-state-locks"
environment       = "shared"
```

**Important**: Choose a globally unique bucket name!

### 2. Deploy Backend Infrastructure

```bash
# Initialize Terraform (local state for backend setup)
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. Note the Outputs

After successful deployment, save the outputs:

```bash
terraform output
```

You'll need these values for configuring the main infrastructure.

## Using the Backend

Once the backend infrastructure is created, configure your main Terraform project to use it.

### Method 1: Backend Config File

Create a file named `backend.hcl` in your main terraform directory:

```hcl
bucket         = "your-terraform-state-bucket"
key            = "terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "terraform-state-locks"
encrypt        = true
```

Then initialize with:

```bash
terraform init -backend-config=backend.hcl
```

### Method 2: Command Line

Initialize with backend configuration:

```bash
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=ap-southeast-2" \
  -backend-config="dynamodb_table=terraform-state-locks" \
  -backend-config="encrypt=true"
```

## Resources Created

- **S3 Bucket**: Stores Terraform state files with versioning enabled
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## Security Features

- S3 bucket versioning enabled
- S3 bucket encryption (AES256)
- Public access blocked on S3 bucket
- DynamoDB table for state locking

## Cleanup

To destroy the backend infrastructure:

```bash
terraform destroy
```

**Warning**: Only destroy after migrating state back to local or ensuring no other projects are using this backend!