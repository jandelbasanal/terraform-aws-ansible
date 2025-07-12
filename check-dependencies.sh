#!/bin/bash
# Dependency check script

# Source version configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/version-config.sh"

echo "🔍 Checking system dependencies..."
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check command existence
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
}

# Function to check version
check_version() {
    local tool=$1
    local required=$2
    local current=$3
    
    if [[ -z "$current" ]]; then
        echo -e "${RED}❌ Could not determine $tool version${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ $tool version: $current${NC}"
    
    # Simple version comparison (works for most cases)
    if [[ "$current" == "$required" ]]; then
        echo -e "${GREEN}✅ Version matches required: $required${NC}"
    elif [[ "$current" > "$required" ]]; then
        echo -e "${GREEN}✅ Version is newer than required: $required${NC}"
    else
        echo -e "${YELLOW}⚠️  Version is older than required: $required${NC}"
        return 1
    fi
}

# Check Ubuntu version
if command -v lsb_release &> /dev/null; then
    UBUNTU_VERSION=$(lsb_release -rs)
    echo -e "${GREEN}✅ Ubuntu version: $UBUNTU_VERSION${NC}"
    
    MAJOR_VERSION=$(echo "$UBUNTU_VERSION" | cut -d. -f1)
    if (( MAJOR_VERSION >= 22 )); then
        echo -e "${GREEN}✅ Ubuntu version is 22.04 or higher${NC}"
    else
        echo -e "${YELLOW}⚠️  Ubuntu version is older than 22.04${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine Ubuntu version${NC}"
fi

echo ""
echo "🔧 Checking required tools..."
echo "============================="

# Check essential tools
MISSING_TOOLS=()

# Check basic tools
for tool in curl wget git unzip python3 pip jq; do
    if ! check_command "$tool"; then
        MISSING_TOOLS+=("$tool")
    fi
done

# Check Terraform
if check_command "terraform"; then
    TERRAFORM_VERSION_CURRENT=$(terraform version | grep -oP 'Terraform v\K[0-9.]+' | head -1)
    if ! check_version "Terraform" "$TERRAFORM_VERSION" "$TERRAFORM_VERSION_CURRENT"; then
        MISSING_TOOLS+=("terraform-upgrade")
    fi
else
    MISSING_TOOLS+=("terraform")
fi

# Check AWS CLI
if check_command "aws"; then
    AWS_VERSION=$(aws --version | grep -oP 'aws-cli/\K[0-9.]+' | head -1)
    if ! check_version "AWS CLI" "$AWS_CLI_VERSION" "$AWS_VERSION"; then
        MISSING_TOOLS+=("aws-cli-upgrade")
    fi
else
    MISSING_TOOLS+=("aws")
fi

# Check Ansible
if check_command "ansible"; then
    ANSIBLE_VERSION_CURRENT=$(ansible --version | grep -oP 'ansible \[core \K[0-9.]+' | head -1)
    if [[ -z "$ANSIBLE_VERSION_CURRENT" ]]; then
        ANSIBLE_VERSION_CURRENT=$(ansible --version | grep -oP 'ansible \K[0-9.]+' | head -1)
    fi
    if ! check_version "Ansible" "$ANSIBLE_VERSION" "$ANSIBLE_VERSION_CURRENT"; then
        MISSING_TOOLS+=("ansible-upgrade")
    fi
else
    MISSING_TOOLS+=("ansible")
fi

echo ""
echo "🔑 Checking AWS credentials..."
echo "============================="

if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
        USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
        echo -e "${GREEN}✅ AWS credentials are configured${NC}"
        echo -e "${GREEN}   Account ID: $ACCOUNT_ID${NC}"
        echo -e "${GREEN}   User/Role: $USER_ARN${NC}"
    else
        echo -e "${RED}❌ AWS credentials are not configured or invalid${NC}"
        MISSING_TOOLS+=("aws-credentials")
    fi
else
    echo -e "${RED}❌ AWS CLI not available${NC}"
fi

echo ""
echo "📋 Summary"
echo "=========="

if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All dependencies are satisfied!${NC}"
    echo -e "${GREEN}You can proceed with the deployment.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Configure terraform.tfvars"
    echo "2. Run: ./deploy.sh /path/to/your/ssh-key.pem"
    exit 0
else
    echo -e "${RED}❌ Missing or outdated dependencies:${NC}"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo -e "${RED}   - $tool${NC}"
    done
    echo ""
    echo -e "${YELLOW}🔧 To fix these issues, run:${NC}"
    echo "   ./setup-execution-machine.sh"
    echo ""
    echo -e "${YELLOW}📋 Manual installation commands:${NC}"
    
    if [[ " ${MISSING_TOOLS[*]} " =~ " terraform " ]] || [[ " ${MISSING_TOOLS[*]} " =~ " terraform-upgrade " ]]; then
        echo "   # Terraform"
        echo "   wget https://releases.hashicorp.com/terraform/1.12.0/terraform_1.12.0_linux_amd64.zip"
        echo "   unzip terraform_1.12.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/"
    fi
    
    if [[ " ${MISSING_TOOLS[*]} " =~ " aws " ]] || [[ " ${MISSING_TOOLS[*]} " =~ " aws-cli-upgrade " ]]; then
        echo "   # AWS CLI"
        echo "   curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
        echo "   unzip awscliv2.zip && sudo ./aws/install"
    fi
    
    if [[ " ${MISSING_TOOLS[*]} " =~ " ansible " ]] || [[ " ${MISSING_TOOLS[*]} " =~ " ansible-upgrade " ]]; then
        echo "   # Ansible"
        echo "   pip3 install 'ansible>=6.0.0'"
    fi
    
    if [[ " ${MISSING_TOOLS[*]} " =~ " aws-credentials " ]]; then
        echo "   # AWS Credentials"
        echo "   aws configure"
    fi
    
    exit 1
fi
