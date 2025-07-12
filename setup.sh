#!/bin/bash
# Quick setup script for Terraform AWS Ansible Infrastructure

echo "🚀 Setting up Terraform AWS Ansible Infrastructure"
echo "================================================="

# Check if we're in the root directory
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "❌ Error: Please run this script from the repository root directory"
    echo "Expected directories: terraform/, ansible/"
    exit 1
fi

echo ""
echo "📁 Repository Structure:"
echo "├── terraform/    # Infrastructure as Code"
echo "├── ansible/      # Configuration Management"
echo "└── README.md     # Main documentation"
echo ""

# Navigate to terraform directory
cd terraform

echo "🔧 Setting up Terraform configuration..."

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    if [ -f "terraform.tfvars.example" ]; then
        echo "📋 Copying terraform.tfvars.example to terraform.tfvars"
        cp terraform.tfvars.example terraform.tfvars
        echo "✅ terraform.tfvars created"
        echo ""
        echo "⚠️  IMPORTANT: Edit terraform.tfvars with your values:"
        echo "   - key_name: Your AWS key pair name (required)"
        echo "   - aws_region: Your preferred AWS region (optional)"
        echo "   - ami_id: AMI ID for your region (optional)"
        echo ""
    else
        echo "❌ Error: terraform.tfvars.example not found"
        exit 1
    fi
else
    echo "✅ terraform.tfvars already exists"
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform not installed"
    echo "Please install Terraform: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

echo "🔍 Validating Terraform configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration validation failed"
    exit 1
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo ""
echo "1. Edit terraform/terraform.tfvars with your AWS settings"
echo "2. Deploy infrastructure:"
echo "   cd terraform"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "3. Test SSH connection:"
echo "   ./test_ssh.sh /path/to/your/key.pem"
echo ""
echo "4. Configure with Ansible (future):"
echo "   cd ../ansible"
echo "   # (Ansible playbooks to be implemented)"
echo ""
echo "📚 Documentation:"
echo "   - Main README: ../README.md"
echo "   - Terraform: ./README.md"
echo "   - Ansible: ../ansible/README.md"
