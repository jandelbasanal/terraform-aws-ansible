#!/bin/bash
# Quick system check script for remote server

echo "🔍 Remote System Check"
echo "====================="

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

# Set proper permissions
chmod 600 "$SSH_KEY_ABSOLUTE"

echo "🔍 Running system compatibility check..."
echo ""

# Test connectivity first
if ! ansible all -i inventory/hosts.ini -m ping -o; then
    echo "❌ Cannot connect to remote server!"
    exit 1
fi

echo ""
echo "📋 System Information:"
echo "====================="

# Get basic system info
ansible all -i inventory/hosts.ini -m setup -a "filter=ansible_distribution*,ansible_memtotal_mb,ansible_architecture,ansible_kernel" --one-line

echo ""
echo "📦 Current Software Status:"
echo "=========================="

# Check PHP
echo "🐘 PHP Status:"
ansible all -i inventory/hosts.ini -m shell -a "php --version 2>/dev/null || echo 'PHP not installed'" --one-line

# Check MySQL
echo "🗄️  MySQL Status:"
ansible all -i inventory/hosts.ini -m shell -a "mysql --version 2>/dev/null || echo 'MySQL not installed'" --one-line

# Check Apache
echo "🌐 Apache Status:"
ansible all -i inventory/hosts.ini -m shell -a "apache2 -v 2>/dev/null || echo 'Apache not installed'" --one-line

echo ""
echo "💾 System Resources:"
echo "==================="

# Check disk space
echo "💿 Disk Space:"
ansible all -i inventory/hosts.ini -m shell -a "df -h /" --one-line

# Check memory
echo "🧠 Memory:"
ansible all -i inventory/hosts.ini -m shell -a "free -h" --one-line

echo ""
echo "🔐 Security Status:"
echo "=================="

# Check if firewall is active
echo "🛡️  Firewall Status:"
ansible all -i inventory/hosts.ini -m shell -a "sudo ufw status || echo 'UFW not configured'" --one-line

# Check for pending updates
echo "🔄 System Updates:"
ansible all -i inventory/hosts.ini -m shell -a "apt list --upgradable 2>/dev/null | wc -l | awk '{print \$1-1 \" packages can be upgraded\"}'" --one-line

echo ""
echo "✅ System check completed!"
echo ""
echo "💡 This check verifies:"
echo "   ✓ Server connectivity and basic info"
echo "   ✓ Current PHP, MySQL, Apache installation status"
echo "   ✓ Available system resources"
echo "   ✓ Security and update status"
echo ""
echo "🚀 To proceed with WordPress deployment:"
echo "   ./test-ansible.sh $SSH_KEY"
