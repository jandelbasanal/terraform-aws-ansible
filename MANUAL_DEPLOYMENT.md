# Manual Deployment Process

## Prerequisites on Local Machine
- [x] Terraform installed
- [x] Ansible installed (`pip install ansible`)
- [x] AWS CLI configured
- [x] SSH key pair available

## Step 1: Deploy AWS Infrastructure
```bash
# Navigate to terraform directory
cd terraform

# Initialize and apply
terraform init
terraform plan
terraform apply

# Get the public IP
terraform output instance_public_ip
# Example output: 3.112.23.45
```

## Step 2: Update Ansible Inventory
```bash
# Navigate to ansible directory
cd ../ansible

# Update inventory with your EC2 public IP
# Replace YOUR_EC2_IP with the actual IP from terraform output
cat > inventory/hosts.ini << 'EOF'
[wordpress]
YOUR_EC2_IP ansible_ssh_private_key_file=/path/to/your/ssh-key.pem

[wordpress:vars]
ansible_user=ubuntu
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
```

## Step 3: Install Ansible Dependencies
```bash
# Install required Python packages
pip install -r requirements.txt
```

## Step 4: Test Ansible Connectivity
```bash
# Test connection to EC2 instance
ansible all -i inventory/hosts.ini -m ping

# Expected output:
# YOUR_EC2_IP | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

## Step 5: Deploy WordPress
```bash
# Run the WordPress deployment playbook
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# This will install:
# - MySQL database
# - Apache web server  
# - PHP
# - WordPress
```

## Step 6: Access WordPress
- **Website**: `http://YOUR_EC2_IP`
- **Admin Panel**: `http://YOUR_EC2_IP/wp-admin`
- **Credentials**: admin / admin123!

## Troubleshooting

### If Terraform fails:
- Check AWS credentials: `aws sts get-caller-identity`
- Verify key pair exists in AWS console
- Check terraform.tfvars configuration

### If Ansible connectivity fails:
- Check security group allows SSH (port 22)
- Verify SSH key permissions: `chmod 600 /path/to/key.pem`
- Test SSH manually: `ssh -i /path/to/key.pem ubuntu@YOUR_EC2_IP`

### If WordPress deployment fails:
- Check EC2 instance is running
- Verify security group allows HTTP (port 80)
- Check Ansible logs for specific errors

## Manual Commands Summary

```bash
# 1. Deploy infrastructure
cd terraform
terraform apply

# 2. Get IP and update inventory
EC2_IP=$(terraform output -raw instance_public_ip)
cd ../ansible
echo "[wordpress]" > inventory/hosts.ini
echo "$EC2_IP ansible_ssh_private_key_file=/path/to/your/key.pem" >> inventory/hosts.ini
echo "" >> inventory/hosts.ini
echo "[wordpress:vars]" >> inventory/hosts.ini
echo "ansible_user=ubuntu" >> inventory/hosts.ini
echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory/hosts.ini

# 3. Deploy WordPress
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```
