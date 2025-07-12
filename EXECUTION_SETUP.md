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
- ✅ Installs/upgrades Terraform to v1.12.2 (exact version enforced)
- ✅ Installs/upgrades AWS CLI to v2.x
- ✅ Installs/upgrades Ansible to v6.0.0+ in virtual environment
- ✅ Sets up proper PATH and environment
- ✅ Installs essential tools (curl, wget, git, jq, etc.)

### 2.1. Version Management (Optional)
```bash
# Check version requirements
./version-manager.sh show

# Check latest versions available
./version-manager.sh check

# Update version requirements if needed
./version-manager.sh update terraform 1.12.3
```

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

# Deploy with one command (make sure you're in the project directory)
cd terraform-aws-ansible
./deploy.sh ~/.ssh/your-aws-key.pem
```

**Note**: The deploy script will automatically detect and change to the correct directory if needed.

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

# Install Terraform v1.12.2
wget https://releases.hashicorp.com/terraform/1.12.2/terraform_1.12.2_linux_amd64.zip
unzip terraform_1.12.2_linux_amd64.zip
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

## Version Management

This project uses a centralized version management system for consistent deployments:

### Current Version Requirements
- **Terraform**: 1.12.2 (enforced exactly)
- **AWS CLI**: 2.0.0+ (minimum v2.x)
- **Ansible**: 6.0.0+ (minimum)
- **Python**: 3.8+ (minimum)
- **Ubuntu**: 22.04+ (recommended)

### Version Commands
```bash
# Check current version requirements
./version-manager.sh show

# Check latest available versions online
./version-manager.sh check

# Update version requirements
./version-manager.sh update terraform 1.12.3
./version-manager.sh update aws-cli 2.15.0

# Re-run setup to install new versions
./setup-execution-machine.sh
```

### Version Enforcement
The setup script (`setup-execution-machine.sh`):
- Enforces exact Terraform version (1.12.2)
- Downloads and installs if current version doesn't match
- Validates installation after completion
- Uses centralized version configuration

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

### Installation Issues:

1. **Terraform Installation Error** (archive conflict):
   ```bash
   # Clean up and retry
   ./cleanup-install.sh
   ./setup-execution-machine.sh
   ```

2. **"cannot delete old terraform" or "Is a directory" errors**:
   ```bash
   # Manual cleanup
   sudo rm -rf terraform terraform_* LICENSE.txt
   sudo rm -f /usr/local/bin/terraform
   rm -f terraform_*.zip*
   
   # Retry setup
   ./setup-execution-machine.sh
   ```

3. **Unzip asking for confirmation** (replace files):
   ```bash
   # The script now handles this automatically with -o flag
   # If you see prompts, answer 'A' for All
   ```

### Deployment Issues:

1. **"Error: Please run this script from the repository root"**:
   ```bash
   # Change to the project directory first
   cd terraform-aws-ansible
   ./deploy.sh ~/.ssh/your-aws-key.pem
   
   # Or run from parent directory (script will auto-detect)
   ./terraform-aws-ansible/deploy.sh ~/.ssh/your-aws-key.pem
   ```

2. **Deploy script exits immediately after "🔍 Checking dependencies..."**:
   ```bash
   # Check if you're in the correct directory
   pwd
   ls -la
   
   # Should see terraform/ and ansible/ directories
   # If not, navigate to terraform-aws-ansible directory
   cd terraform-aws-ansible
   ls -la
   ```

3. **Script can't find dependencies**:
   ```bash
   # Check if setup was run correctly
   ./check-dependencies.sh
   
   # Source the correct PATH
   source ~/.bashrc
   export PATH="/usr/local/bin:$PATH"
   ```

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
