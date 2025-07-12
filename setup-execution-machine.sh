#!/bin/bash
# Optimized setup script for Ubuntu 22.04+ execution machine

set -e

# Source version configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/version-config.sh"

echo "🛠️  Setting up execution machine for Terraform + Ansible deployment"
echo "================================================================="

# Check if running on Ubuntu 22.04+
if ! command -v apt &> /dev/null; then
    echo "❌ This script is designed for Ubuntu/Debian systems"
    exit 1
fi

# Check Ubuntu version
UBUNTU_VERSION_CURRENT=$(lsb_release -rs 2>/dev/null || echo "unknown")
if [[ "$UBUNTU_VERSION_CURRENT" != "unknown" ]]; then
    MAJOR_VERSION=$(echo "$UBUNTU_VERSION_CURRENT" | cut -d. -f1)
    if (( MAJOR_VERSION < 22 )); then
        echo "⚠️  Warning: This script is optimized for Ubuntu 22.04+. Current version: $UBUNTU_VERSION_CURRENT"
        echo "Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    echo "✅ Ubuntu version: $UBUNTU_VERSION_CURRENT"
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
echo "📦 Installing essential tools..."
sudo apt install -y curl wget git unzip python3 python3-pip python3-venv \
    software-properties-common apt-transport-https ca-certificates gnupg \
    lsb-release jq

# Function to compare versions
version_compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # Fill empty fields with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # Fill empty with zero
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

# Install/Upgrade Terraform
echo "📦 Checking Terraform installation..."
REQUIRED_TERRAFORM_VERSION="$TERRAFORM_VERSION"
CURRENT_TERRAFORM_VERSION=""

if command -v terraform &> /dev/null; then
    CURRENT_TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | grep -oP 'Terraform v\K[0-9.]+' | head -1)
    echo "Current Terraform version: $CURRENT_TERRAFORM_VERSION"
    
    if [[ "$CURRENT_TERRAFORM_VERSION" == "$REQUIRED_TERRAFORM_VERSION" ]]; then
        echo "✅ Terraform version matches required: $REQUIRED_TERRAFORM_VERSION"
        INSTALL_TERRAFORM=false
    else
        echo "⚠️  Terraform version $CURRENT_TERRAFORM_VERSION does not match required $REQUIRED_TERRAFORM_VERSION"
        echo "🔄 Installing Terraform $REQUIRED_TERRAFORM_VERSION..."
        INSTALL_TERRAFORM=true
    fi
else
    echo "❌ Terraform not found"
    echo "📥 Installing Terraform $REQUIRED_TERRAFORM_VERSION..."
    INSTALL_TERRAFORM=true
fi

if [[ "$INSTALL_TERRAFORM" == "true" ]]; then
    # Create temporary directory for download
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Remove old terraform if exists
    if command -v terraform &> /dev/null; then
        echo "🗑️  Removing existing Terraform installation..."
        sudo rm -f /usr/local/bin/terraform
    fi
    
    # Clean up any existing terraform files in current directory
    rm -rf terraform terraform_* LICENSE.txt 2>/dev/null || true
    
    # Download specific version
    echo "📥 Downloading Terraform $REQUIRED_TERRAFORM_VERSION..."
    TERRAFORM_ZIP="terraform_${REQUIRED_TERRAFORM_VERSION}_linux_amd64.zip"
    
    # Check if specific version exists and download
    if curl -s -f "https://releases.hashicorp.com/terraform/${REQUIRED_TERRAFORM_VERSION}/${TERRAFORM_ZIP}" --head >/dev/null 2>&1; then
        wget "https://releases.hashicorp.com/terraform/${REQUIRED_TERRAFORM_VERSION}/${TERRAFORM_ZIP}"
        
        # Extract with overwrite (quiet mode)
        unzip -o "$TERRAFORM_ZIP" >/dev/null 2>&1
        
        # Verify terraform binary exists
        if [[ -f "./terraform" ]]; then
            chmod +x ./terraform
            sudo mv ./terraform /usr/local/bin/
            echo "✅ Terraform binary installed to /usr/local/bin/"
        else
            echo "❌ Terraform binary not found after extraction"
            exit 1
        fi
        
        # Clean up temporary files
        rm -f "$TERRAFORM_ZIP" LICENSE.txt 2>/dev/null || true
        
        # Return to original directory
        cd - >/dev/null
        rm -rf "$TEMP_DIR"
        
        # Verify installation
        INSTALLED_VERSION=$(terraform version | grep -oP 'Terraform v\K[0-9.]+' | head -1)
        if [[ "$INSTALLED_VERSION" == "$REQUIRED_TERRAFORM_VERSION" ]]; then
            echo "✅ Terraform $REQUIRED_TERRAFORM_VERSION installed successfully"
        else
            echo "❌ Terraform installation failed. Got version: $INSTALLED_VERSION"
            exit 1
        fi
    else
        echo "❌ Terraform version $REQUIRED_TERRAFORM_VERSION not found in HashiCorp releases"
        echo "Available versions: https://releases.hashicorp.com/terraform/"
        exit 1
    fi
else
    echo "✅ Terraform is already at the required version: $CURRENT_TERRAFORM_VERSION"
fi

# Install AWS CLI v2
echo "📦 Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version | grep -oP 'aws-cli/\K[0-9.]+')
    echo "Current AWS CLI version: $AWS_VERSION"
    
    # Check if it's v2 (version 2.x.x)
    if [[ "$AWS_VERSION" =~ ^2\. ]]; then
        echo "✅ AWS CLI v2 is already installed"
    else
        echo "⚠️  AWS CLI v1 detected, upgrading to v2..."
        INSTALL_AWS_CLI=true
    fi
else
    echo "❌ AWS CLI not found"
    echo "� Installing AWS CLI v2..."
    INSTALL_AWS_CLI=true
fi

if [[ "$INSTALL_AWS_CLI" == "true" ]]; then
    # Create temporary directory for download
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Remove old AWS CLI if exists
    if command -v aws &> /dev/null; then
        echo "🗑️  Removing existing AWS CLI installation..."
        sudo rm -rf /usr/local/aws-cli 2>/dev/null || true
        sudo rm -f /usr/local/bin/aws 2>/dev/null || true
        sudo rm -f /usr/local/bin/aws_completer 2>/dev/null || true
    fi
    
    # Install AWS CLI v2
    echo "📥 Downloading AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    
    # Extract with overwrite (quiet mode)
    unzip -o awscliv2.zip >/dev/null 2>&1
    
    # Install
    sudo ./aws/install --update 2>/dev/null || sudo ./aws/install
    
    # Clean up
    rm -rf aws awscliv2.zip
    cd - >/dev/null
    rm -rf "$TEMP_DIR"
    
    # Verify installation
    AWS_INSTALLED_VERSION=$(aws --version | grep -oP 'aws-cli/\K[0-9.]+')
    echo "✅ AWS CLI installed: v$AWS_INSTALLED_VERSION"
fi

# Install/Upgrade Ansible
echo "📦 Checking Ansible installation..."
REQUIRED_ANSIBLE_VERSION="$ANSIBLE_VERSION"

if command -v ansible &> /dev/null; then
    CURRENT_ANSIBLE_VERSION=$(ansible --version | grep -oP 'ansible \[core \K[0-9.]+' | head -1)
    if [[ -z "$CURRENT_ANSIBLE_VERSION" ]]; then
        CURRENT_ANSIBLE_VERSION=$(ansible --version | grep -oP 'ansible \K[0-9.]+' | head -1)
    fi
    echo "Current Ansible version: $CURRENT_ANSIBLE_VERSION"
    
    version_compare "$CURRENT_ANSIBLE_VERSION" "$REQUIRED_ANSIBLE_VERSION"
    case $? in
        0) echo "✅ Ansible version is exactly $REQUIRED_ANSIBLE_VERSION" ;;
        1) echo "✅ Ansible version $CURRENT_ANSIBLE_VERSION is newer than required $REQUIRED_ANSIBLE_VERSION" ;;
        2) 
            echo "⚠️  Ansible version $CURRENT_ANSIBLE_VERSION is older than required $REQUIRED_ANSIBLE_VERSION"
            echo "🔄 Upgrading Ansible..."
            INSTALL_ANSIBLE=true
            ;;
    esac
else
    echo "❌ Ansible not found"
    echo "� Installing Ansible..."
    INSTALL_ANSIBLE=true
fi

if [[ "$INSTALL_ANSIBLE" == "true" ]]; then
    # Create Python virtual environment for Ansible (best practice)
    echo "📦 Setting up Python virtual environment for Ansible..."
    python3 -m venv ~/.ansible-venv
    source ~/.ansible-venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install Ansible and required packages
    pip install "ansible>=$REQUIRED_ANSIBLE_VERSION" PyMySQL boto3 botocore six
    
    # Create symlink for global access
    sudo ln -sf ~/.ansible-venv/bin/ansible /usr/local/bin/ansible
    sudo ln -sf ~/.ansible-venv/bin/ansible-playbook /usr/local/bin/ansible-playbook
    sudo ln -sf ~/.ansible-venv/bin/ansible-galaxy /usr/local/bin/ansible-galaxy
    
    # Add to bash profile for persistent activation
    echo 'export PATH="$HOME/.ansible-venv/bin:$PATH"' >> ~/.bashrc
    
    # Verify installation
    ANSIBLE_INSTALLED_VERSION=$(~/.ansible-venv/bin/ansible --version | grep -oP 'ansible \[core \K[0-9.]+' | head -1)
    if [[ -z "$ANSIBLE_INSTALLED_VERSION" ]]; then
        ANSIBLE_INSTALLED_VERSION=$(~/.ansible-venv/bin/ansible --version | grep -oP 'ansible \K[0-9.]+' | head -1)
    fi
    echo "✅ Ansible installed: v$ANSIBLE_INSTALLED_VERSION"
else
    echo "✅ Ansible already installed: v$CURRENT_ANSIBLE_VERSION"
fi

# Create directory for keys
echo "📁 Creating SSH keys directory..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Set up proper PATH
echo "🔧 Setting up PATH..."
if ! grep -q '/usr/local/bin' ~/.bashrc; then
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
fi

# Source bashrc to update current session
export PATH="/usr/local/bin:$PATH"

echo ""
echo "🎉 Setup completed successfully!"
echo "================================"
echo ""
echo "📋 Installed versions:"
echo "   Terraform: $(terraform version | grep -oP 'Terraform v\K[0-9.]+' | head -1)"
echo "   AWS CLI: $(aws --version | grep -oP 'aws-cli/\K[0-9.]+' | head -1)"
echo "   Ansible: $(ansible --version | grep -oP 'ansible \[core \K[0-9.]+' | head -1 || ansible --version | grep -oP 'ansible \K[0-9.]+' | head -1)"
echo "   Python: $(python3 --version | grep -oP 'Python \K[0-9.]+' | head -1)"
echo ""
echo "📋 Next steps:"
echo "1. Configure AWS credentials:"
echo "   aws configure"
echo "   # OR set environment variables:"
echo "   export AWS_ACCESS_KEY_ID='your-key'"
echo "   export AWS_SECRET_ACCESS_KEY='your-secret'"
echo "   export AWS_DEFAULT_REGION='ap-northeast-1'"
echo ""
echo "2. Upload your AWS SSH key pair:"
echo "   scp -i access-key.pem aws-key.pem ubuntu@this-server:~/.ssh/"
echo "   chmod 600 ~/.ssh/aws-key.pem"
echo ""
echo "3. Clone and deploy:"
echo "   git clone https://github.com/yourusername/terraform-aws-ansible.git"
echo "   cd terraform-aws-ansible"
echo "   cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
echo "   # Edit terraform.tfvars with your settings"
echo "   ./deploy.sh ~/.ssh/aws-key.pem"
echo ""
echo "🔄 To apply changes to current session:"
echo "   source ~/.bashrc"
echo ""
echo "🔍 Verify installation:"
echo "   terraform version"
echo "   aws --version"
echo "   ansible --version"
echo "   aws sts get-caller-identity"
