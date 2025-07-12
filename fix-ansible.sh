#!/bin/bash
# Quick fix for current Ansible issues

echo "🔧 Quick Fix for Ansible Issues"
echo "==============================="

# Fix 1: Install missing Python packages
echo "📦 Installing missing Python packages..."
if [ -d ~/.ansible-venv ]; then
    echo "Using Ansible virtual environment..."
    source ~/.ansible-venv/bin/activate
    pip install six boto3 botocore
else
    echo "Installing globally..."
    pip3 install six boto3 botocore
fi

# Fix 2: Update inventory with absolute path
echo "📝 Fixing inventory SSH key path..."
if [ -f "ansible/inventory/hosts.ini" ]; then
    # Get the absolute path to wtv.pem
    SSH_KEY_ABSOLUTE=$(realpath "wtv.pem")
    
    if [ -f "$SSH_KEY_ABSOLUTE" ]; then
        echo "SSH Key found at: $SSH_KEY_ABSOLUTE"
        
        # Update inventory
        sed -i "s|ansible_ssh_private_key_file=wtv.pem|ansible_ssh_private_key_file=$SSH_KEY_ABSOLUTE|" ansible/inventory/hosts.ini
        
        # Update ansible.cfg
        sed -i "s|private_key_file = ~/.ssh/your-key.pem|private_key_file = $SSH_KEY_ABSOLUTE|" ansible/ansible.cfg
        
        echo "✅ Updated inventory and ansible.cfg with absolute path"
    else
        echo "❌ SSH key not found at: $SSH_KEY_ABSOLUTE"
        echo "Please provide the correct path to your SSH key"
        exit 1
    fi
else
    echo "❌ Inventory file not found"
    exit 1
fi

# Fix 3: Set proper permissions
echo "🔒 Setting SSH key permissions..."
chmod 600 "$SSH_KEY_ABSOLUTE"

# Fix 4: Test connectivity
echo "🔍 Testing Ansible connectivity..."
if [ -d ~/.ansible-venv ]; then
    source ~/.ansible-venv/bin/activate
fi

cd ansible
ansible all -i inventory/hosts.ini -m ping -vv

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Ansible connectivity test passed!"
    echo "📦 You can now run the WordPress playbook:"
    echo "  cd ansible"
    echo "  ansible-playbook -i inventory/hosts.ini playbooks/site.yml"
else
    echo ""
    echo "❌ Connectivity test still failing"
    echo "🔍 Debug info:"
    echo "  SSH Key: $SSH_KEY_ABSOLUTE"
    echo "  Inventory content:"
    cat inventory/hosts.ini
    echo ""
    echo "🔧 Try manual SSH:"
    echo "  ssh -i $SSH_KEY_ABSOLUTE ubuntu@<IP_ADDRESS>"
fi
