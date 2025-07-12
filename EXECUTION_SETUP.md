# Execution Machine Setup Guide (Ubuntu 22.04+)

## Overview
This guide helps you set up a fresh Ubuntu 22.04+ server to execute the Terraform + Ansible WordPress deployment with automatic dependency management.

## Quick Setup (Recommended)

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/terraform-aws-ansible.git
cd terraform-aws-ansible
```

### 2. Run Automated Setup
```bash
chmod +x setup-execution-machine.sh
./setup-execution-machine.sh
```

This script automatically:
- ✅ Checks Ubuntu version (optimized for 22.04+)
- ✅ Installs/upgrades Terraform to v1.12.0+
- ✅ Installs/upgrades AWS CLI to v2.x
- ✅ Installs/upgrades Ansible to v6.0.0+ in virtual environment
- ✅ Sets up proper PATH and environment
- ✅ Installs essential tools (curl, wget, git, jq, etc.)

### 3. Configure AWS Credentials
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

### 4. Deploy WordPress
```bash
# Configure terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your settings

# Deploy with one command
./deploy.sh ~/.ssh/your-aws-key.pem
```

## Manual Setup (Alternative)

### Prerequisites Check
```bash
# Check all dependencies
chmod +x check-dependencies.sh
./check-dependencies.sh
```

### Install Tools Manually
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git unzip python3 python3-pip python3-venv \
    software-properties-common apt-transport-https ca-certificates gnupg \
    lsb-release jq

# Install Terraform v1.12.0
wget https://releases.hashicorp.com/terraform/1.12.0/terraform_1.12.0_linux_amd64.zip
unzip terraform_1.12.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install Ansible v6.0.0+ in virtual environment
python3 -m venv ~/.ansible-venv
source ~/.ansible-venv/bin/activate
pip install --upgrade pip
pip install 'ansible>=6.0.0' PyMySQL boto3 botocore

# Create global symlinks
sudo ln -sf ~/.ansible-venv/bin/ansible /usr/local/bin/ansible
sudo ln -sf ~/.ansible-venv/bin/ansible-playbook /usr/local/bin/ansible-playbook
```

## Security Considerations

### For Production Deployments:
```bash
# 1. Use environment variables for sensitive data
export TF_VAR_key_name="your-key-name"

# 2. Use Ansible Vault for passwords
ansible-vault create group_vars/all/vault.yml
# Add encrypted variables:
# vault_mysql_root_password: "secure_password"
# vault_wordpress_admin_password: "secure_password"

# 3. Run with vault
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-vault-pass
```

### Restrict Access:
```bash
# Limit SSH access to specific IPs in security group
# Edit terraform/modules/ec2/security_group.tf
# Change: cidr_blocks = ["0.0.0.0/0"]
# To: cidr_blocks = ["your.ip.address/32"]
```

## Troubleshooting

### Common Issues:
1. **Permission Denied (SSH Key)**:
   ```bash
   chmod 600 ~/your-aws-key.pem
   ```

2. **AWS Credentials Not Found**:
   ```bash
   aws sts get-caller-identity
   aws configure list
   ```

3. **Terraform/Ansible Not Found**:
   ```bash
   which terraform
   which ansible
   export PATH=$PATH:/usr/local/bin
   ```

## Repository Updates

When you update the repository:
```bash
# On execution machine
cd terraform-aws-ansible
git pull origin main

# If infrastructure changed, update it
cd terraform
terraform plan
terraform apply

# If Ansible playbooks changed, re-run them
cd ../ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

## Cleanup

To destroy the infrastructure:
```bash
cd terraform
terraform destroy
```
