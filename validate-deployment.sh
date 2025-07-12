#!/bin/bash
# Pre-deployment validation and system preparation

echo "🔍 Pre-Deployment System Validation"
echo "===================================="

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
sed -i "s|private_key_file = .*|private_key_file = $SSH_KEY_ABSOLUTE|" ansible.cfg

# Set proper permissions
chmod 600 "$SSH_KEY_ABSOLUTE"

echo ""
echo "🔍 Testing connectivity..."
if ! ansible all -i inventory/hosts.ini -m ping -o; then
    echo "❌ Cannot connect to remote server!"
    echo "Please check:"
    echo "  1. SSH key path and permissions"
    echo "  2. EC2 instance is running"
    echo "  3. Security group allows SSH (port 22)"
    exit 1
fi

echo "✅ Connectivity successful!"
echo ""

# Run system preparation checks
echo "🔍 Running system preparation playbook (dry run)..."
if ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags "system-prep" --check; then
    echo "✅ System preparation check passed!"
else
    echo "❌ System preparation check failed!"
    echo "Please review the errors above."
    exit 1
fi

echo ""
echo "📋 Deployment Readiness Summary:"
echo "==============================="

# Get target server IP
TARGET_IP=$(grep -oP '(\d+\.){3}\d+' inventory/hosts.ini | head -1)
echo "🎯 Target server: $TARGET_IP"

# Check system requirements
echo "🔍 Checking WordPress requirements..."

# Memory check
MEMORY_MB=$(ansible all -i inventory/hosts.ini -m shell -a "free -m | awk 'NR==2{print \$2}'" --one-line | awk '{print $NF}')
if [ "$MEMORY_MB" -lt 1024 ]; then
    echo "⚠️  Warning: Low memory ($MEMORY_MB MB). WordPress may run slowly."
    echo "   Recommendation: Upgrade to at least 1GB RAM"
else
    echo "✅ Memory: $MEMORY_MB MB (sufficient)"
fi

# Disk space check
DISK_AVAIL=$(ansible all -i inventory/hosts.ini -m shell -a "df / | awk 'NR==2{print \$4}'" --one-line | awk '{print $NF}')
DISK_AVAIL_GB=$((DISK_AVAIL / 1024 / 1024))
if [ "$DISK_AVAIL_GB" -lt 5 ]; then
    echo "⚠️  Warning: Low disk space ($DISK_AVAIL_GB GB available)"
    echo "   Recommendation: Ensure at least 5GB free space"
else
    echo "✅ Disk space: $DISK_AVAIL_GB GB available (sufficient)"
fi

# OS compatibility check
OS_INFO=$(ansible all -i inventory/hosts.ini -m setup -a "filter=ansible_distribution*" --one-line | grep -oP 'ansible_distribution.*?Ubuntu.*?ansible_distribution_version.*?[0-9]+\.[0-9]+')
if echo "$OS_INFO" | grep -q "Ubuntu"; then
    OS_VERSION=$(echo "$OS_INFO" | grep -oP '[0-9]+\.[0-9]+')
    if [[ "$OS_VERSION" > "20.04" ]] || [[ "$OS_VERSION" == "20.04" ]]; then
        echo "✅ OS: Ubuntu $OS_VERSION (compatible)"
    else
        echo "⚠️  Warning: Ubuntu $OS_VERSION may not be fully supported"
        echo "   Recommendation: Use Ubuntu 20.04 or later"
    fi
else
    echo "⚠️  OS compatibility needs verification"
fi

echo ""
echo "🚀 Deployment Plan:"
echo "=================="
echo "1. ✅ System preparation and compatibility checks"
echo "2. 🔄 Install/upgrade to latest software versions:"
echo "   - PHP 8.3 (latest stable)"
echo "   - MySQL 8.0 (latest stable)"
echo "   - Apache 2.4"
echo "3. 🛠️  Configure LAMP stack"
echo "4. 📥 Download and install WordPress"
echo "5. 🔧 Configure WordPress with database"
echo "6. 🔐 Set up security and firewall"

echo ""
echo "⏱️  Estimated deployment time: 5-10 minutes"
echo ""

read -p "🚀 Ready to proceed with WordPress deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting WordPress deployment..."
    cd .. # Return to project root
    ./test-ansible.sh "$SSH_KEY"
else
    echo "🛑 Deployment cancelled by user."
    echo "💡 You can run this validation again anytime:"
    echo "   ./validate-deployment.sh $SSH_KEY"
fi
