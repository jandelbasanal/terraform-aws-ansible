#!/bin/bash
# Test PHP repository setup

echo "🧪 Testing PHP Repository Setup"
echo "==============================="

# Check if SSH key path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <ssh-key-path>"
    echo "Example: $0 ~/.ssh/my-key.pem"
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
sed -i "s|private_key_file = .*|private_key_file = $SSH_KEY_ABSOLUTE|" ansible.cfg

# Set proper permissions
chmod 600 "$SSH_KEY_ABSOLUTE"

echo ""
echo "🔍 Testing connectivity..."
if ! ansible all -i inventory/hosts.ini -m ping -o; then
    echo "❌ Cannot connect to remote server!"
    exit 1
fi

echo ""
echo "🧪 Testing system preparation (PHP repository setup)..."
echo "This will run only the system-prep tasks to test the PHP repository fix."
echo ""

# Run only the system-prep role
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags "system-prep" -v

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ System preparation test completed successfully!"
    echo ""
    echo "🔍 Checking PHP repository status..."
    ansible all -i inventory/hosts.ini -m shell -a "apt-cache policy | grep -i ondrej || echo 'Using default repositories'" --one-line
    
    echo ""
    echo "🐘 Available PHP versions:"
    ansible all -i inventory/hosts.ini -m shell -a "apt-cache search '^php[0-9]' | head -10" --one-line
    
    echo ""
    echo "🚀 Repository setup successful! You can now run the full deployment:"
    echo "   ./test-ansible.sh $SSH_KEY"
else
    echo ""
    echo "❌ System preparation test failed!"
    echo "Check the error messages above for troubleshooting."
    
    echo ""
    echo "🔍 Debug information:"
    echo "Checking internet connectivity and DNS..."
    ansible all -i inventory/hosts.ini -m shell -a "ping -c 1 google.com" --one-line
    
    echo ""
    echo "Checking Ubuntu version..."
    ansible all -i inventory/hosts.ini -m setup -a "filter=ansible_distribution*" --one-line
fi
