#!/bin/bash
# WordPress Deployment Wrapper - Run from anywhere

echo "🚀 WordPress Deployment Wrapper"
echo "=============================="

# Check if SSH key argument is provided
if [ $# -eq 0 ]; then
    echo "❌ Usage: $0 <ssh-key-path>"
    echo "Example: $0 ~/.ssh/your-aws-key.pem"
    exit 1
fi

SSH_KEY="$1"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH key not found: $SSH_KEY"
    exit 1
fi

echo "🔑 SSH Key: $SSH_KEY"

# Find terraform-aws-ansible directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=""

# Check current directory
if [ -d "terraform" ] && [ -d "ansible" ]; then
    PROJECT_DIR="$(pwd)"
    echo "📁 Found project in current directory"
elif [ -d "terraform-aws-ansible" ]; then
    PROJECT_DIR="$(pwd)/terraform-aws-ansible"
    echo "📁 Found project in terraform-aws-ansible subdirectory"
elif [ -d "../terraform-aws-ansible" ]; then
    PROJECT_DIR="$(cd ../terraform-aws-ansible && pwd)"
    echo "📁 Found project in parent directory"
else
    echo "❌ Could not locate terraform-aws-ansible project"
    echo "Please run this script from:"
    echo "  - Project root (where terraform/ and ansible/ exist)"
    echo "  - Directory containing terraform-aws-ansible/"
    echo "  - Subdirectory of terraform-aws-ansible/"
    exit 1
fi

echo "📂 Project directory: $PROJECT_DIR"

# Change to project directory and run deployment
cd "$PROJECT_DIR"
echo "🚀 Starting deployment..."
./deploy.sh "$SSH_KEY"
