#!/bin/bash
# Quick manual fix for the current SSH key path issue

echo "🔧 Quick Manual Fix for SSH Key Path"
echo "===================================="

# Check if SSH key path is provided as parameter
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ssh-key-path>"
    echo "Example: $0 ~/.ssh/my-key.pem"
    echo "Example: $0 ./wtv.pem"
    exit 1
fi

SSH_KEY_PROVIDED="$1"

# Get the current directory and resolve SSH key path
CURRENT_DIR=$(pwd)
echo "Current directory: $CURRENT_DIR"

# Convert to absolute path
SSH_KEY_CORRECT=$(realpath "$SSH_KEY_PROVIDED")

echo "Looking for SSH key at: $SSH_KEY_CORRECT"

if [ -f "$SSH_KEY_CORRECT" ]; then
    echo "✅ SSH key found!"
    
    # Fix the inventory file
    echo "📝 Updating inventory file..."
    sed -i "s|ansible_ssh_private_key_file=.*|ansible_ssh_private_key_file=$SSH_KEY_CORRECT|" ansible/inventory/hosts.ini
    
    # Fix the ansible.cfg file
    echo "📝 Updating ansible.cfg file..."
    sed -i "s|private_key_file = .*|private_key_file = $SSH_KEY_CORRECT|" ansible/ansible.cfg
    
    # Set proper permissions
    echo "🔒 Setting SSH key permissions..."
    chmod 600 "$SSH_KEY_CORRECT"
    
    echo "✅ Files updated!"
    echo ""
    echo "📋 Updated inventory content:"
    cat ansible/inventory/hosts.ini
    echo ""
    echo "📋 Updated ansible.cfg (key line):"
    grep "private_key_file" ansible/ansible.cfg
    echo ""
    
    # Test connectivity
    echo "🔍 Testing connectivity..."
    cd ansible
    ansible all -i inventory/hosts.ini -m ping
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ SUCCESS! Ansible connectivity is working!"
        echo "📦 You can now run the WordPress playbook:"
        echo "  cd ansible"
        echo "  ansible-playbook -i inventory/hosts.ini playbooks/site.yml"
    else
        echo ""
        echo "❌ Still having issues. Let's debug..."
        echo "🔍 Current inventory:"
        cat inventory/hosts.ini
        echo ""
        echo "🔧 Try direct SSH test:"
        echo "  ssh -i $SSH_KEY_CORRECT ubuntu@<IP_FROM_INVENTORY>"
    fi
else
    echo "❌ SSH key not found at: $SSH_KEY_CORRECT"
    echo "Please check the SSH key location."
    echo "Provided: $SSH_KEY_PROVIDED"
    echo "Resolved: $SSH_KEY_CORRECT"
    ls -la "$SSH_KEY_PROVIDED" 2>/dev/null || echo "File does not exist"
fi
