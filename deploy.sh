#!/bin/bash
# Terraform + Ansible WordPress Deployment Script

set -e

echo "🚀 Starting Terraform + Ansible WordPress Deployment"
echo "===================================================="

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Check if we're in the correct directory, if not try to find it
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "⚠️  Not in repository root, attempting to locate..."
    
    # Try to find terraform-aws-ansible directory
    if [ -d "terraform-aws-ansible" ]; then
        echo "📁 Found terraform-aws-ansible directory, changing to it..."
        cd terraform-aws-ansible
        REPO_ROOT="$(pwd)"
    elif [ -d "../terraform-aws-ansible" ]; then
        echo "📁 Found terraform-aws-ansible directory (parent), changing to it..."
        cd ../terraform-aws-ansible
        REPO_ROOT="$(pwd)"
    else
        echo "❌ Error: Could not find terraform-aws-ansible directory"
        echo "Please run this script from:"
        echo "  - Repository root (where terraform/ and ansible/ exist)"
        echo "  - A directory containing terraform-aws-ansible/"
        echo "  - Parent directory of terraform-aws-ansible/"
        echo ""
        echo "Current directory: $(pwd)"
        echo "Script location: $SCRIPT_DIR"
        exit 1
    fi
fi

# Verify we're now in the correct directory
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "❌ Error: Still not in correct directory after location attempt"
    echo "Expected structure: terraform/ and ansible/ directories"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "📁 Working directory: $(pwd)"
echo "🔍 Checking dependencies..."

# Source version configuration
source "$REPO_ROOT/version-config.sh"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    echo "Run: ./setup-execution-machine.sh"
    exit 1
fi

# Check Terraform version
REQUIRED_TERRAFORM_VERSION="$TERRAFORM_VERSION"
CURRENT_TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | grep -oP 'Terraform v\K[0-9.]+' | head -1)

version_compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

version_compare "$CURRENT_TERRAFORM_VERSION" "$REQUIRED_TERRAFORM_VERSION"
case $? in
    2) 
        echo "❌ Terraform version $CURRENT_TERRAFORM_VERSION is older than required $REQUIRED_TERRAFORM_VERSION"
        echo "Please upgrade Terraform. Run: ./setup-execution-machine.sh"
        exit 1
        ;;
    *) 
        echo "✅ Terraform version: $CURRENT_TERRAFORM_VERSION"
        ;;
esac

# Check Ansible
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found. Please install Ansible first."
    echo "Run: ./setup-execution-machine.sh"
    exit 1
fi

# Check for required Python packages for Ansible
echo "🔍 Checking Ansible Python dependencies..."
if ! python3 -c "import boto3, botocore, six" 2>/dev/null; then
    echo "⚠️  Missing Python dependencies (boto3/botocore/six)"
    echo "Installing required packages..."
    if [ -d ~/.ansible-venv ]; then
        echo "Using existing Ansible virtual environment..."
        source ~/.ansible-venv/bin/activate
        pip install boto3 botocore six
    else
        echo "Installing globally..."
        pip3 install boto3 botocore six
    fi
fi

# Ensure we're using the correct Ansible environment
if [ -d ~/.ansible-venv ]; then
    echo "🔧 Activating Ansible virtual environment..."
    source ~/.ansible-venv/bin/activate
    export PATH="~/.ansible-venv/bin:$PATH"
fi

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    echo "Run: ./setup-execution-machine.sh"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured or invalid"
    echo "Please run: aws configure"
    echo "Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION"
    exit 1
fi

# Check jq for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found, installing..."
    if command -v apt &> /dev/null; then
        sudo apt install -y jq
    else
        echo "❌ Please install jq manually"
        exit 1
    fi
fi

# Check if SSH key is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide SSH key path"
    echo "Usage: $0 <path_to_ssh_key>"
    echo "Example: $0 ~/.ssh/my-key.pem"
    exit 1
fi

SSH_KEY_PATH="$1"

# Resolve SSH key path early - before changing directories
# This ensures relative paths are resolved from the original working directory
SSH_KEY_ABSOLUTE=$(realpath "$SSH_KEY_PATH")

# Validate SSH key exists
if [ ! -f "$SSH_KEY_ABSOLUTE" ]; then
    echo "❌ Error: SSH key not found at $SSH_KEY_ABSOLUTE"
    echo "Original path provided: $SSH_KEY_PATH"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Set proper permissions on SSH key
chmod 600 "$SSH_KEY_ABSOLUTE"

echo "✅ Dependencies check passed"
echo "✅ SSH key found: $SSH_KEY_ABSOLUTE"
echo "📁 Original SSH key path: $SSH_KEY_PATH"

# Step 1: Deploy infrastructure with Terraform
echo ""
echo "🏗️  Step 1: Deploying AWS infrastructure with Terraform..."
cd terraform

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Error: terraform.tfvars not found"
    echo "Please create terraform.tfvars from terraform.tfvars.example"
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning Terraform deployment..."
terraform plan

# Apply deployment
echo "Applying Terraform deployment..."
terraform apply -auto-approve

# Get the public IP
PUBLIC_IP=$(terraform output -raw instance_public_ip)
if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Error: Could not get public IP from Terraform output"
    exit 1
fi

echo "✅ Infrastructure deployed successfully!"
echo "✅ EC2 Public IP: $PUBLIC_IP"

# Step 2: Wait for EC2 instance to be ready
echo ""
echo "⏳ Step 2: Waiting for EC2 instance to be ready..."
cd ..

# Wait for SSH to be available
echo "Waiting for SSH to be available on $PUBLIC_IP..."
for i in {1..30}; do
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@"$PUBLIC_IP" "echo 'SSH Ready'" 2>/dev/null; then
        echo "✅ SSH connection established!"
        break
    fi
    echo "Attempt $i/30 - SSH not ready yet, waiting 10 seconds..."
    sleep 10
done

# Step 3: Configure dynamic inventory
echo ""
echo "📝 Step 3: Configuring Ansible inventory..."
cd ansible

# Update inventory with the actual IP and SSH key (using pre-resolved absolute path)
cat > inventory/hosts.ini << EOF
[wordpress]
$PUBLIC_IP

[wordpress:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=$SSH_KEY_ABSOLUTE
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Update ansible.cfg with the correct key path
sed -i.bak "s|private_key_file = .*|private_key_file = $SSH_KEY_ABSOLUTE|" ansible.cfg

echo "✅ Inventory configured with IP: $PUBLIC_IP"
echo "✅ SSH key path in inventory: $SSH_KEY_ABSOLUTE"

# Step 4: Deploy WordPress with Ansible
echo ""
echo "📦 Step 4: Deploying WordPress with Ansible..."

# Ensure we're using the correct Ansible environment
if [ -d ~/.ansible-venv ]; then
    source ~/.ansible-venv/bin/activate
fi

# Test connectivity first
echo "Testing Ansible connectivity..."
ansible all -i inventory/hosts.ini -m ping -vv

if [ $? -eq 0 ]; then
    echo "✅ Ansible connectivity test passed!"
else
    echo "❌ Ansible connectivity test failed!"
    echo "🔍 Troubleshooting info:"
    echo "  SSH Key: $SSH_KEY_ABSOLUTE"
    echo "  Target IP: $PUBLIC_IP"
    echo "  Inventory file:"
    cat inventory/hosts.ini
    echo ""
    echo "🔧 Try manual SSH test:"
    echo "  ssh -i $SSH_KEY_ABSOLUTE ubuntu@$PUBLIC_IP"
    exit 1
fi

# Run the WordPress playbook
echo "Running WordPress deployment playbook..."
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 WordPress deployment completed successfully!"
    echo "=================================================="
    echo ""
    echo "🌐 Access your WordPress site:"
    echo "   Site URL: http://$PUBLIC_IP"
    echo "   Admin URL: http://$PUBLIC_IP/wp-admin"
    echo ""
    echo "🔑 Default credentials:"
    echo "   Username: admin"
    echo "   Password: admin123!"
    echo ""
    echo "⚠️  Security Notes:"
    echo "   - Change the default admin password immediately"
    echo "   - Consider setting up SSL/TLS certificates"
    echo "   - Update WordPress and plugins regularly"
    echo "   - Review security group settings"
    echo ""
    echo "🛠️  Management:"
    echo "   - SSH to server: ssh -i $SSH_KEY_ABSOLUTE ubuntu@$PUBLIC_IP"
    echo "   - View logs: tail -f /var/log/apache2/error.log"
    echo "   - Restart services: sudo systemctl restart apache2"
else
    echo "❌ WordPress deployment failed!"
    exit 1
fi
