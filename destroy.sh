#!/bin/bash
# Terraform AWS Infrastructure Destroy Script

set -e

echo "🗑️  Terraform AWS Infrastructure Destroy"
echo "========================================"

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Check if we're in the correct directory, if not try to find it
if [ ! -d "terraform" ]; then
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
        echo "  - Repository root (where terraform/ directory exists)"
        echo "  - A directory containing terraform-aws-ansible/"
        echo "  - Parent directory of terraform-aws-ansible/"
        exit 1
    fi
fi

# Verify terraform directory exists
if [ ! -d "terraform" ]; then
    echo "❌ Error: terraform/ directory not found"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Check dependencies
echo "🔍 Checking dependencies..."

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    echo "Run: ./setup-execution-machine.sh"
    exit 1
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
    exit 1
fi

echo "✅ Dependencies check passed"

# Change to terraform directory
echo ""
echo "📂 Changing to terraform directory..."
cd terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    echo "⚠️  No terraform state file found"
    echo "This might mean:"
    echo "  - No resources were created"
    echo "  - Resources were already destroyed"
    echo "  - State file is in a different location"
    echo ""
    echo "Checking for remote state..."
    if [ -f ".terraform/terraform.tfstate" ]; then
        echo "✅ Found remote state file"
    else
        echo "❌ No state file found"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled by user"
            exit 0
        fi
    fi
fi

# Initialize Terraform (in case it's not initialized)
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Show current state
echo ""
echo "📋 Current Terraform state:"
terraform show

# Plan destroy
echo ""
echo "📋 Planning destroy operation..."
terraform plan -destroy

# Confirm destroy
echo ""
echo "⚠️  WARNING: This will destroy all AWS resources managed by Terraform!"
echo "This action cannot be undone."
echo ""
read -p "Are you sure you want to destroy all resources? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Destroy cancelled by user"
    exit 0
fi

# Destroy resources
echo ""
echo "🗑️  Destroying AWS resources..."
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ AWS resources destroyed successfully!"
    echo ""
    echo "📋 Cleanup completed:"
    echo "  - All AWS resources have been destroyed"
    echo "  - Terraform state has been updated"
    echo "  - No charges should be incurred"
    echo ""
    echo "🧹 Optional cleanup:"
    echo "  - Remove terraform.tfstate files: rm -f terraform.tfstate*"
    echo "  - Remove .terraform directory: rm -rf .terraform"
    echo "  - Remove Ansible inventory: rm -f ../ansible/inventory/hosts.ini"
else
    echo ""
    echo "❌ Destroy operation failed!"
    echo "Please check the error messages above and try again."
    echo ""
    echo "🔍 Troubleshooting:"
    echo "  - Check AWS credentials: aws sts get-caller-identity"
    echo "  - Check terraform state: terraform show"
    echo "  - Manual cleanup might be needed in AWS Console"
    exit 1
fi
