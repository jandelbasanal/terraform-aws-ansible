#!/bin/bash
# Cleanup script for failed installations

echo "🧹 Cleaning up failed installations..."
echo "===================================="

# Function to safely remove files/directories
safe_remove() {
    local path=$1
    if [[ -e "$path" ]]; then
        echo "🗑️  Removing: $path"
        sudo rm -rf "$path" 2>/dev/null || true
    fi
}

# Clean up Terraform files
echo "📦 Cleaning up Terraform files..."
safe_remove "/usr/local/bin/terraform"
safe_remove "./terraform"
safe_remove "./terraform_*"
safe_remove "./LICENSE.txt"
rm -f terraform_*.zip* 2>/dev/null || true

# Clean up AWS CLI files
echo "📦 Cleaning up AWS CLI files..."
safe_remove "/usr/local/aws-cli"
safe_remove "/usr/local/bin/aws"
safe_remove "/usr/local/bin/aws_completer"
safe_remove "./aws"
safe_remove "./awscliv2.zip"
rm -f awscliv2.zip* 2>/dev/null || true

# Clean up temporary directories
echo "📦 Cleaning up temporary directories..."
rm -rf /tmp/terraform_* /tmp/aws* 2>/dev/null || true

# Clean up any stuck processes
echo "📦 Checking for stuck processes..."
if pgrep -f "terraform" >/dev/null 2>&1; then
    echo "⚠️  Found running terraform processes"
    sudo pkill -f "terraform" 2>/dev/null || true
fi

if pgrep -f "aws" >/dev/null 2>&1; then
    echo "⚠️  Found running aws processes"
    sudo pkill -f "aws" 2>/dev/null || true
fi

# Reset PATH
echo "📦 Resetting PATH..."
export PATH=$(echo $PATH | tr ':' '\n' | grep -v '/usr/local/bin' | tr '\n' ':')
export PATH="/usr/local/bin:$PATH"

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run the setup script again:"
echo "   ./setup-execution-machine.sh"
echo ""
echo "2. If issues persist, check for manual installation:"
echo "   which terraform"
echo "   which aws"
echo "   terraform version"
echo "   aws --version"
echo ""
echo "3. For manual cleanup of specific tools:"
echo "   # Remove Terraform:"
echo "   sudo rm -f /usr/local/bin/terraform"
echo ""
echo "   # Remove AWS CLI:"
echo "   sudo rm -rf /usr/local/aws-cli"
echo "   sudo rm -f /usr/local/bin/aws"
echo "   sudo rm -f /usr/local/bin/aws_completer"
echo ""
echo "   # Remove Ansible virtual environment:"
echo "   rm -rf ~/.ansible-venv"
echo "   sudo rm -f /usr/local/bin/ansible*"
