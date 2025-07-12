# Terraform AWS Infrastructure

This directory contains Terraform configuration for deploying AWS infrastructure including VPC, subnets, and EC2 instances with SSH access.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.12.0
- An AWS Key Pair created in your target region

## Usage

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:
   - `key_name`: Name of your AWS key pair (required)
   - `aws_region`: AWS region (defaults to ap-northeast-1)
   - `ami_id`: AMI ID for EC2 instances (defaults to Ubuntu 24.04 LTS)

4. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Module Structure

```
modules/
├── vpc/           # VPC with DNS support
├── subnet/        # Public subnets with Internet Gateway
└── ec2/          # EC2 instance with Security Group
```

## Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `aws_region` | AWS region for resources | string | `ap-northeast-1` | No |
| `key_name` | Name of the AWS key pair for EC2 instances | string | - | Yes |
| `ami_id` | AMI ID for EC2 instances | string | `ami-054400ced365b82a0` | No |

## Outputs

- `instance_public_ip`: Public IP address of the created EC2 instance

## SSH Access

After applying the configuration, you can SSH to the EC2 instance:

```bash
# Get the public IP from Terraform output
terraform output instance_public_ip

# SSH to the instance (replace with your key file and IP)
ssh -i /path/to/your/key.pem ubuntu@<public_ip>
```

### Security Group Configuration

The EC2 instance is configured with a security group that allows:
- **Inbound**: SSH (port 22) from anywhere (0.0.0.0/0)
- **Outbound**: All traffic

**Security Note**: The security group allows SSH from anywhere (0.0.0.0/0) for demo purposes. In production, restrict this to your specific IP range by modifying the security group in `modules/ec2/security_group.tf`:

```terraform
cidr_blocks = ["your.ip.address/32"]
```

## Infrastructure Components

- **VPC**: Custom VPC (10.10.0.0/16) with DNS support
- **Public Subnets**: 
  - Subnet 1: 10.10.1.0/24 (dynamically assigned AZ)
  - Subnet 2: 10.10.2.0/24 (dynamically assigned AZ)
- **Internet Gateway**: For public internet access
- **Security Group**: SSH access (port 22) from anywhere
- **EC2 Instance**: Ubuntu 24.04 LTS t2.micro instance

## Security

- Never commit `terraform.tfvars` to version control
- State files are excluded from git via `.gitignore`
- Use IAM roles and policies following the principle of least privilege
