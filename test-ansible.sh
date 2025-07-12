#!/bin/bash
# Test Ansible setup and run WordPress deployment

echo "🧪 Ansible WordPress Deployment Test"
echo "====================================="

# Check if SSH key path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ssh-key-path>"
    echo "Example: $0 ~/.ssh/my-key.pem"
    echo "Example: $0 ./wtv.pem"
    exit 1
fi

SSH_KEY="$1"
SSH_KEY_ABSOLUTE=$(realpath "$SSH_KEY")

echo "🔑 Using SSH key: $SSH_KEY_ABSOLUTE"

# Check if we're in the right directory
if [ ! -d "ansible" ]; then
    echo "❌ Please run this script from the terraform-aws-ansible directory"
    exit 1
fi

# Change to ansible directory
cd ansible

# Check if inventory exists
if [ ! -f "inventory/hosts.ini" ]; then
    echo "❌ Inventory file not found: inventory/hosts.ini"
    echo "Please run the deployment script first to create the inventory"
    exit 1
fi

# Update inventory with correct SSH key
echo "📝 Updating inventory with SSH key..."
sed -i "s|ansible_ssh_private_key_file=.*|ansible_ssh_private_key_file=$SSH_KEY_ABSOLUTE|" inventory/hosts.ini

# Update ansible.cfg
echo "📝 Updating ansible.cfg with SSH key..."
sed -i "s|private_key_file = .*|private_key_file = $SSH_KEY_ABSOLUTE|" ansible.cfg

# Set proper permissions
echo "🔒 Setting SSH key permissions..."
chmod 600 "$SSH_KEY_ABSOLUTE"

# Show current configuration
echo "📋 Current inventory:"
cat inventory/hosts.ini
echo ""

# Test connectivity
echo "🔍 Testing Ansible connectivity..."
ansible all -i inventory/hosts.ini -m ping

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Connectivity test passed!"
    
    # Optional: Run system check first
    echo "� Checking target system information..."
    ansible all -i inventory/hosts.ini -m setup -a "filter=ansible_distribution*,ansible_memtotal_mb,ansible_architecture"
    
    echo ""
    echo "�🚀 Starting WordPress deployment with system preparation..."
    echo "📋 This will:"
    echo "   1. 🔍 Check OS version and compatibility"
    echo "   2. 📦 Check existing PHP/MySQL installations"
    echo "   3. 🔄 Install/upgrade to latest versions if needed"
    echo "   4. 🛠️  Configure WordPress environment"
    echo ""
    
    # Run the WordPress playbook
    ansible-playbook -i inventory/hosts.ini playbooks/site.yml
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 WordPress deployment completed successfully!"
        echo "Check the output above for your WordPress site details."
    else
        echo ""
        echo "❌ WordPress deployment failed!"
        echo "Check the error messages above for troubleshooting."
    fi
else
    echo ""
    echo "❌ Connectivity test failed!"
    echo "Please check:"
    echo "  1. SSH key path: $SSH_KEY_ABSOLUTE"
    echo "  2. EC2 instance is running"
    echo "  3. Security group allows SSH (port 22)"
    echo "  4. Try manual SSH: ssh -i $SSH_KEY_ABSOLUTE ubuntu@<IP>"
fi
