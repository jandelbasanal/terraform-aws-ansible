#!/bin/bash
# Fix Ansible environment issues - handles version and dependency problems

set -e

echo "🔧 Fixing Ansible Environment Issues"
echo "====================================="

# Check if we have Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3 first."
    exit 1
fi

# Function to check if a Python module is available
check_python_module() {
    local module=$1
    if [ -d ~/.ansible-venv ]; then
        source ~/.ansible-venv/bin/activate
        python3 -c "import $module" 2>/dev/null
    else
        python3 -c "import $module" 2>/dev/null
    fi
}

# Check current Ansible installation
echo "� Checking current Ansible installation..."
if command -v ansible &> /dev/null; then
    CURRENT_VERSION=$(ansible --version 2>/dev/null | head -1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
    echo "Current Ansible version: $CURRENT_VERSION"
else
    echo "Ansible not found"
    CURRENT_VERSION="none"
fi

# Check if we should use virtual environment
USE_VENV=false
if [ -d ~/.ansible-venv ]; then
    echo "✅ Using existing Ansible virtual environment"
    USE_VENV=true
    source ~/.ansible-venv/bin/activate
fi

# Check for critical issues
NEEDS_UPGRADE=false
MISSING_DEPS=()

# Check for six module (critical for older Ansible versions)
if ! check_python_module "six"; then
    echo "❌ Missing critical module: six"
    MISSING_DEPS+=("six")
    NEEDS_UPGRADE=true
fi

# Check for AWS modules
if ! check_python_module "boto3"; then
    echo "❌ Missing AWS module: boto3"
    MISSING_DEPS+=("boto3")
fi

if ! check_python_module "botocore"; then
    echo "❌ Missing AWS module: botocore"
    MISSING_DEPS+=("botocore")
fi

# Check if Ansible version is too old
if [[ "$CURRENT_VERSION" =~ ^2\.[0-9]\. ]] || [[ "$CURRENT_VERSION" == "unknown" ]]; then
    echo "⚠️  Ansible version $CURRENT_VERSION is too old or incompatible"
    NEEDS_UPGRADE=true
fi

# Perform fixes
if [ "$NEEDS_UPGRADE" = true ] || [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "🔄 Fixing Ansible installation..."
    
    if [ "$USE_VENV" = true ]; then
        source ~/.ansible-venv/bin/activate
        echo "Using virtual environment: ~/.ansible-venv"
    fi
    
    # Upgrade pip first
    if [ "$USE_VENV" = true ]; then
        pip install --upgrade pip setuptools wheel
    else
        pip3 install --upgrade pip setuptools wheel
    fi
    
    # Install six first (critical)
    if [[ " ${MISSING_DEPS[*]} " =~ " six " ]]; then
        echo "🔄 Installing six module..."
        if [ "$USE_VENV" = true ]; then
            pip install six
        else
            pip3 install six
        fi
    fi
    
    # Install AWS dependencies
    if [[ " ${MISSING_DEPS[*]} " =~ " boto3 " ]]; then
        echo "🔄 Installing boto3..."
        if [ "$USE_VENV" = true ]; then
            pip install boto3
        else
            pip3 install boto3
        fi
    fi
    
    if [[ " ${MISSING_DEPS[*]} " =~ " botocore " ]]; then
        echo "🔄 Installing botocore..."
        if [ "$USE_VENV" = true ]; then
            pip install botocore
        else
            pip3 install botocore
        fi
    fi
    
    # Upgrade Ansible if needed
    if [ "$NEEDS_UPGRADE" = true ]; then
        echo "🔄 Upgrading Ansible..."
        if [ "$USE_VENV" = true ]; then
            pip install --upgrade 'ansible>=4.0.0,<6.0.0'
            pip install --upgrade 'ansible-core>=2.11.0,<2.13.0'
        else
            pip3 install --upgrade 'ansible>=4.0.0,<6.0.0'
            pip3 install --upgrade 'ansible-core>=2.11.0,<2.13.0'
        fi
    fi
    
    # Verify the fixes
    echo "✅ Verifying fixes..."
    
    # Check Ansible version
    if [ "$USE_VENV" = true ]; then
        source ~/.ansible-venv/bin/activate
    fi
    
    NEW_VERSION=$(ansible --version 2>/dev/null | head -1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
    echo "✅ New Ansible version: $NEW_VERSION"
    
    # Check Python modules
    STILL_MISSING=()
    for module in six boto3 botocore; do
        if ! check_python_module "$module"; then
            STILL_MISSING+=("$module")
        fi
    done
    
    if [ ${#STILL_MISSING[@]} -gt 0 ]; then
        echo "❌ Still missing modules: ${STILL_MISSING[*]}"
        echo "For complete fix, run: ./fix-ansible-complete.sh"
        exit 1
    fi
    
    echo "✅ All dependencies verified"
    
else
    echo "✅ Ansible environment looks good!"
fi

# Fix SSH key path in inventory (if needed)
echo "📝 Checking SSH key path in inventory..."
if [ -f "ansible/inventory/hosts.ini" ]; then
    # Check if there's a relative path that needs fixing
    if grep -q "ansible_ssh_private_key_file=wtv.pem" ansible/inventory/hosts.ini; then
        echo "🔄 Fixing SSH key path in inventory..."
        SSH_KEY_ABSOLUTE=""
        
        # Check if wtv.pem exists in current directory
        if [ -f "wtv.pem" ]; then
            SSH_KEY_ABSOLUTE=$(realpath "wtv.pem")
        # Check if wtv.pem exists in parent directory
        elif [ -f "../wtv.pem" ]; then
            SSH_KEY_ABSOLUTE=$(realpath "../wtv.pem")
        # Check if it's already in ansible directory
        elif [ -f "ansible/wtv.pem" ]; then
            SSH_KEY_ABSOLUTE=$(realpath "ansible/wtv.pem")
        fi
        
        if [ -n "$SSH_KEY_ABSOLUTE" ] && [ -f "$SSH_KEY_ABSOLUTE" ]; then
            sed -i "s|ansible_ssh_private_key_file=wtv.pem|ansible_ssh_private_key_file=$SSH_KEY_ABSOLUTE|" ansible/inventory/hosts.ini
            echo "✅ SSH key path updated to: $SSH_KEY_ABSOLUTE"
        else
            echo "⚠️  SSH key 'wtv.pem' not found for path update"
        fi
    else
        echo "✅ SSH key path looks good"
    fi
fi

echo ""
echo "🎉 Ansible fixes complete!"
echo "=========================="
echo "✅ Ansible version: $(ansible --version | head -1)"
echo "✅ Python modules: six, boto3, botocore"
if [ "$USE_VENV" = true ]; then
    echo "✅ Virtual environment: ~/.ansible-venv"
fi
echo ""
echo "🚀 You can now run: ./deploy.sh <ssh-key-path>"
        sed -i "s|ansible_ssh_private_key_file=.*/wtv.pem|ansible_ssh_private_key_file=$SSH_KEY_ABSOLUTE|" ansible/inventory/hosts.ini
        
        # Update ansible.cfg
        sed -i "s|private_key_file = ~/.ssh/your-key.pem|private_key_file = $SSH_KEY_ABSOLUTE|" ansible/ansible.cfg
        sed -i "s|private_key_file = .*/wtv.pem|private_key_file = $SSH_KEY_ABSOLUTE|" ansible/ansible.cfg
        
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
