# Terraform AWS Ansible Infrastructure

This Terraform configuration creates AWS infrastructure including VPC, subnets, and EC2 instances.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.12.0
- An AWS Key Pair created in your target region

## Usage

1. Clone this repository
2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your values:
   - `key_name`: Name of your AWS key pair
   - `aws_region`: AWS region (defaults to ap-northeast-1)
   - `ami_id`: AMI ID for EC2 instances (defaults to Ubuntu 24.04 LTS)

4. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `aws_region` | AWS region for resources | string | `ap-northeast-1` | No |
| `key_name` | Name of the AWS key pair for EC2 instances | string | - | Yes |
| `ami_id` | AMI ID for EC2 instances | string | `ami-054400ced365b82a0` | No |

## Outputs

- `instance_public_ip`: Public IP address of the created EC2 instance

## Security

- Never commit `terraform.tfvars` to version control
- State files are excluded from git via `.gitignore`
- Use IAM roles and policies following the principle of least privilege
