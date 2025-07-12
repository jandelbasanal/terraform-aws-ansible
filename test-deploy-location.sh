#!/bin/bash
# Test deployment script directory detection

echo "🧪 Testing deployment script directory detection..."
echo "================================================="

# Test from different locations
echo "Current directory: $(pwd)"
echo "Looking for terraform-aws-ansible..."

if [ -d "terraform-aws-ansible" ]; then
    echo "✅ Found terraform-aws-ansible directory"
    cd terraform-aws-ansible
    echo "📁 Changed to: $(pwd)"
    echo "📋 Directory contents:"
    ls -la | head -10
    echo ""
    echo "🔍 Checking for required directories:"
    if [ -d "terraform" ]; then
        echo "✅ terraform/ directory found"
    else
        echo "❌ terraform/ directory not found"
    fi
    
    if [ -d "ansible" ]; then
        echo "✅ ansible/ directory found"
    else
        echo "❌ ansible/ directory not found"
    fi
    
    echo ""
    echo "📝 To run deployment from here:"
    echo "  ./deploy.sh ~/.ssh/your-aws-key.pem"
    echo ""
    echo "📝 To run from parent directory:"
    echo "  ./terraform-aws-ansible/deploy.sh ~/.ssh/your-aws-key.pem"
    
else
    echo "❌ terraform-aws-ansible directory not found"
    echo "📁 Current directory contents:"
    ls -la
    echo ""
    echo "📝 Please navigate to the directory containing terraform-aws-ansible"
fi
