#!/bin/bash
# Enhanced Terraform + Ansible WordPress Deployment Script with Multi-Python Environment Support

set -e

echo "🚀 Starting Enhanced Terraform + Ansible WordPress Deployment"
echo "=============================================================="

# Get script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Check if we're in the correct directory, if not try to find it
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "⚠️  Not in repository root, attempting to locate..."
    
    # Try to find terraform-aws-ansible directory
    if [ -d "terraform-aws-ansible" ]; then
        echo "📁 Found terraform-aws-ansible directory, changing to it..."
        cd terraform-aws-ansible
        REPO_ROOT="$(pwd)"
    elif [ -d "../terraform-aws-ansible" ]; then
        echo "📁 Found terraform-aws-ansible directory (parent), changing to it..."
        cd ../terraform-aws-ansible
        REPO_ROOT="$(pwd)"
    else
        echo "❌ Error: Could not find terraform-aws-ansible directory"
        echo "Please run this script from:"
        echo "  - Repository root (where terraform/ and ansible/ exist)"
        echo "  - A directory containing terraform-aws-ansible/"
        echo "  - Parent directory of terraform-aws-ansible/"
        echo ""
        echo "Current directory: $(pwd)"
        echo "Script location: $SCRIPT_DIR"
        exit 1
    fi
fi

# Verify we're now in the correct directory
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "❌ Error: Still not in correct directory after location attempt"
    echo "Expected structure: terraform/ and ansible/ directories"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "📁 Working directory: $(pwd)"

# Source version configuration
if [ -f version-config.sh ]; then
    echo "📋 Loading version configuration..."
    source version-config.sh
fi

# Advanced Python Environment Detection and Ansible Management
echo "🔍 Detecting Python environment and Ansible installation..."

# Initialize environment variables
PYTHON_ENV_TYPE=""
PYTHON_CMD=""
CONDA_ENV=""
PYENV_VERSION=""

# Function to detect Python environment
detect_python_environment() {
    # Check for conda
    if command -v conda &> /dev/null; then
        CONDA_ENV=$(conda info --envs 2>/dev/null | grep "^\*" | awk '{print $1}' || echo "")
        if [ -n "$CONDA_ENV" ] && [ "$CONDA_ENV" != "base" ]; then
            PYTHON_ENV_TYPE="conda"
            echo "✅ Detected active Conda environment: $CONDA_ENV"
            return 0
        fi
    fi
    
    # Check for active virtual environment
    if [ -n "$VIRTUAL_ENV" ]; then
        PYTHON_ENV_TYPE="venv"
        echo "✅ Detected active virtual environment: $VIRTUAL_ENV"
        return 0
    fi
    
    # Check for our Ansible virtual environment
    if [ -d ~/.ansible-venv ]; then
        PYTHON_ENV_TYPE="ansible-venv"
        echo "✅ Found Ansible virtual environment: ~/.ansible-venv"
        source ~/.ansible-venv/bin/activate
        export PATH="~/.ansible-venv/bin:$PATH"
        return 0
    fi
    
    # Check for pyenv
    if command -v pyenv &> /dev/null; then
        PYENV_VERSION=$(pyenv version-name 2>/dev/null || echo "")
        if [ -n "$PYENV_VERSION" ] && [ "$PYENV_VERSION" != "system" ]; then
            PYTHON_ENV_TYPE="pyenv"
            echo "✅ Detected pyenv environment: $PYENV_VERSION"
            return 0
        fi
    fi
    
    # Default to system Python
    PYTHON_ENV_TYPE="system"
    echo "ℹ️  Using system Python environment"
    return 0
}

# Function to find best Python command
find_python_command() {
    local python_candidates=("python3.11" "python3.10" "python3.9" "python3.8" "python3" "python")
    
    for py_cmd in "${python_candidates[@]}"; do
        if command -v $py_cmd &> /dev/null; then
            local py_version=$($py_cmd --version 2>&1 | grep -oP 'Python \K[0-9.]+' || echo "0.0.0")
            # Check if version is >= 3.8
            if [[ "$py_version" > "3.7" ]]; then
                PYTHON_CMD=$py_cmd
                echo "✅ Selected Python: $py_cmd ($py_version)"
                return 0
            fi
        fi
    done
    
    echo "❌ No suitable Python version found (need Python 3.8+)"
    return 1
}

# Function to check if a Python module is available
check_python_module() {
    local module=$1
    
    case "$PYTHON_ENV_TYPE" in
        "conda")
            if [ -n "$CONDA_ENV" ]; then
                conda run -n "$CONDA_ENV" python -c "import $module" 2>/dev/null
            else
                python -c "import $module" 2>/dev/null
            fi
            ;;
        "venv"|"ansible-venv")
            if [ -n "$VIRTUAL_ENV" ] || [ -d ~/.ansible-venv ]; then
                [ -d ~/.ansible-venv ] && source ~/.ansible-venv/bin/activate 2>/dev/null
                python3 -c "import $module" 2>/dev/null
            else
                python3 -c "import $module" 2>/dev/null
            fi
            ;;
        "pyenv")
            if command -v pyenv &> /dev/null && [ -n "$PYENV_VERSION" ]; then
                pyenv exec python -c "import $module" 2>/dev/null
            else
                python3 -c "import $module" 2>/dev/null
            fi
            ;;
        *)
            $PYTHON_CMD -c "import $module" 2>/dev/null
            ;;
    esac
}

# Function to install Python packages
install_python_package() {
    local package=$1
    local success=false
    
    echo "🔧 Installing $package..."
    
    case "$PYTHON_ENV_TYPE" in
        "conda")
            if [ -n "$CONDA_ENV" ]; then
                (conda install -y $package 2>/dev/null || conda install -y -c conda-forge $package 2>/dev/null || pip install $package) && success=true
            else
                pip install $package && success=true
            fi
            ;;
        "venv"|"ansible-venv")
            if [ -d ~/.ansible-venv ]; then
                source ~/.ansible-venv/bin/activate 2>/dev/null
                pip install $package && success=true
            elif [ -n "$VIRTUAL_ENV" ]; then
                pip install $package && success=true
            else
                pip3 install $package && success=true
            fi
            ;;
        "pyenv")
            if command -v pyenv &> /dev/null && [ -n "$PYENV_VERSION" ]; then
                pyenv exec pip install $package && success=true
            else
                pip3 install $package && success=true
            fi
            ;;
        *)
            pip3 install $package && success=true
            ;;
    esac
    
    if [ "$success" = true ]; then
        echo "✅ Successfully installed $package"
    else
        echo "❌ Failed to install $package"
        return 1
    fi
}

# Initialize environment
detect_python_environment
find_python_command || exit 1

# Check if Ansible is available
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found. Installing Ansible..."
    
    # Create virtual environment if using system Python
    if [ "$PYTHON_ENV_TYPE" = "system" ]; then
        echo "🔧 Creating isolated Ansible environment..."
        $PYTHON_CMD -m venv ~/.ansible-venv
        PYTHON_ENV_TYPE="ansible-venv"
        source ~/.ansible-venv/bin/activate
        export PATH="~/.ansible-venv/bin:$PATH"
    fi
    
    # Install Ansible
    install_python_package "--upgrade pip setuptools wheel"
    install_python_package "six"
    install_python_package "boto3"
    install_python_package "botocore"
    install_python_package "'ansible>=4.0.0,<6.0.0'"
    install_python_package "'ansible-core>=2.11.0,<2.13.0'"
fi

# Check Ansible version and fix compatibility issues
ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
echo "🔍 Current Ansible version: $ANSIBLE_VERSION"

# Check for critical Python dependency issues
NEEDS_UPGRADE=false
MISSING_DEPS=()

# Check for six module (critical for older Ansible versions)
if ! check_python_module "six"; then
    MISSING_DEPS+=("six")
    NEEDS_UPGRADE=true
fi

# Check for AWS modules
if ! check_python_module "boto3"; then
    MISSING_DEPS+=("boto3")
fi

if ! check_python_module "botocore"; then
    MISSING_DEPS+=("botocore")
fi

# Check if we need to upgrade Ansible for compatibility
if [[ "$ANSIBLE_VERSION" =~ ^2\.[0-9]\. ]] || [[ "$ANSIBLE_VERSION" == "unknown" ]] || [[ "$NEEDS_UPGRADE" == true ]]; then
    echo "⚠️  Detected compatibility issues with Ansible version ($ANSIBLE_VERSION)"
    echo "🔄 Installing newer Ansible version with all dependencies..."
    
    # Create virtual environment if using system Python and no other env
    if [ "$PYTHON_ENV_TYPE" = "system" ] && [ ! -d ~/.ansible-venv ]; then
        echo "🔧 Creating isolated Ansible environment..."
        $PYTHON_CMD -m venv ~/.ansible-venv
        PYTHON_ENV_TYPE="ansible-venv"
        source ~/.ansible-venv/bin/activate
        export PATH="~/.ansible-venv/bin:$PATH"
    fi
    
    # Install/upgrade core dependencies
    echo "🔧 Upgrading pip and core tools..."
    install_python_package "--upgrade pip setuptools wheel"
    
    # Install six first (critical dependency)
    echo "🔧 Installing six module (critical dependency)..."
    install_python_package "six"
    
    # Install AWS dependencies
    echo "🔧 Installing AWS dependencies..."
    install_python_package "boto3"
    install_python_package "botocore"
    
    # Upgrade to a more compatible Ansible version
    echo "🔧 Installing compatible Ansible version..."
    install_python_package "'ansible>=4.0.0,<6.0.0'"
    install_python_package "'ansible-core>=2.11.0,<2.13.0'"
    
    # Verify the installation
    NEW_ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
    echo "✅ Updated Ansible version: $NEW_ANSIBLE_VERSION"
    
    # Re-check dependencies
    echo "🔍 Verifying Python dependencies after upgrade..."
    FAILED_DEPS=()
    
    for dep in six boto3 botocore; do
        if ! check_python_module "$dep"; then
            FAILED_DEPS+=("$dep")
        fi
    done
    
    if [ ${#FAILED_DEPS[@]} -gt 0 ]; then
        echo "❌ Critical error: Still missing modules after upgrade: ${FAILED_DEPS[*]}"
        echo "Environment: $PYTHON_ENV_TYPE"
        echo "Python command: $PYTHON_CMD"
        
        # Try one more time with force reinstall
        echo "🔄 Attempting force reinstall of missing dependencies..."
        for dep in "${FAILED_DEPS[@]}"; do
            install_python_package "--force-reinstall --no-deps $dep"
        done
        
        # Final check
        STILL_FAILED=()
        for dep in "${FAILED_DEPS[@]}"; do
            if ! check_python_module "$dep"; then
                STILL_FAILED+=("$dep")
            fi
        done
        
        if [ ${#STILL_FAILED[@]} -gt 0 ]; then
            echo "❌ Critical error: Cannot install required modules: ${STILL_FAILED[*]}"
            echo "Please check your Python environment and permissions"
            exit 1
        fi
    fi
    
    echo "✅ All Python dependencies verified"
    
else
    # Just install missing dependencies if Ansible version is OK
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo "⚠️  Installing missing Python dependencies: ${MISSING_DEPS[*]}"
        for dep in "${MISSING_DEPS[@]}"; do
            install_python_package "$dep"
        done
    fi
fi

# Final environment summary
echo "📋 Environment Summary:"
echo "  Python Environment: $PYTHON_ENV_TYPE"
echo "  Python Command: $PYTHON_CMD"
echo "  Ansible Version: $(ansible --version | head -1)"
case "$PYTHON_ENV_TYPE" in
    "conda")
        echo "  Conda Environment: $CONDA_ENV"
        ;;
    "venv"|"ansible-venv")
        echo "  Virtual Environment: ${VIRTUAL_ENV:-~/.ansible-venv}"
        ;;
    "pyenv")
        echo "  PyEnv Version: $PYENV_VERSION"
        ;;
esac

# Check other required tools
echo "🔍 Checking other required tools..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    echo "Run: ./setup-execution-machine.sh"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured or invalid"
    echo "Please run: aws configure"
    echo "Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION"
    exit 1
fi

# Check jq for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found, installing..."
    if command -v apt &> /dev/null; then
        sudo apt install -y jq
    else
        echo "❌ Please install jq manually"
        exit 1
    fi
fi

# Check if SSH key is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide SSH key path"
    echo "Usage: $0 <path_to_ssh_key>"
    echo "Example: $0 ~/.ssh/my-key.pem"
    exit 1
fi

SSH_KEY_PATH="$1"

# Resolve SSH key path early - before changing directories
# This ensures relative paths are resolved from the original working directory
SSH_KEY_ABSOLUTE=$(realpath "$SSH_KEY_PATH")

# Validate SSH key exists
if [ ! -f "$SSH_KEY_ABSOLUTE" ]; then
    echo "❌ Error: SSH key not found at $SSH_KEY_ABSOLUTE"
    echo "Please check the path and try again"
    exit 1
fi

# Set proper permissions on SSH key
chmod 600 "$SSH_KEY_ABSOLUTE"
echo "✅ SSH key found and permissions set: $SSH_KEY_ABSOLUTE"

echo ""
echo "📦 Step 1: Deploying Infrastructure with Terraform..."
echo "===================================================="

# Navigate to terraform directory
cd terraform

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Error: terraform.tfvars not found"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it"
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply the deployment
echo "🚀 Applying Terraform deployment..."
terraform apply tfplan

# Get the public IP of the instance
echo "🔍 Retrieving instance information..."
INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "✅ Instance IP: $INSTANCE_IP"

# Wait for instance to be ready
echo "⏳ Waiting for instance to be ready..."
sleep 60

# Test SSH connectivity
echo "🔍 Testing SSH connectivity..."
for i in {1..5}; do
    if ssh -i "$SSH_KEY_ABSOLUTE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$INSTANCE_IP "echo 'SSH connection successful'" &> /dev/null; then
        echo "✅ SSH connection successful"
        break
    else
        echo "⏳ SSH connection failed, retrying in 30 seconds... ($i/5)"
        sleep 30
    fi
done

# Return to project root
cd "$REPO_ROOT"

echo ""
echo "📦 Step 2: Configuring Ansible Inventory..."
echo "============================================"

# Update Ansible inventory with the instance IP and SSH key
INVENTORY_FILE="ansible/inventory/hosts.ini"

# Create the inventory content
cat > "$INVENTORY_FILE" << EOF
[wordpress]
$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=$SSH_KEY_ABSOLUTE

[wordpress:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo "✅ Inventory updated with:"
echo "  - Instance IP: $INSTANCE_IP"
echo "  - SSH Key: $SSH_KEY_ABSOLUTE"
echo "  - User: ubuntu"

echo ""
echo "📦 Step 3: Updating Ansible Configuration..."
echo "============================================="

# Update ansible.cfg with the SSH key path
ANSIBLE_CFG="ansible/ansible.cfg"
sed -i "s|^private_key_file = .*|private_key_file = $SSH_KEY_ABSOLUTE|" "$ANSIBLE_CFG"
echo "✅ Ansible configuration updated with SSH key path"

echo ""
echo "📦 Step 4: Deploying WordPress with Ansible..."
echo "==============================================="

# Navigate to ansible directory
cd ansible

# Test Ansible connectivity
echo "Testing Ansible connectivity..."
ansible --version
ansible -i inventory/hosts.ini all -m ping

# Run the WordPress deployment playbook
echo "🚀 Running WordPress deployment playbook..."
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# Return to project root
cd "$REPO_ROOT"

echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo "✅ Infrastructure deployed with Terraform"
echo "✅ WordPress configured with Ansible"
echo ""
echo "🌐 Your WordPress site is available at:"
echo "   http://$INSTANCE_IP"
echo ""
echo "🔐 WordPress Admin Access:"
echo "   URL: http://$INSTANCE_IP/wp-admin"
echo "   Username: admin"
echo "   Password: admin123!"
echo ""
echo "⚠️  Important: Change the default admin password immediately!"
echo ""
echo "📝 To destroy the infrastructure later, run:"
echo "   ./destroy.sh"
echo ""
echo "📋 Environment used:"
echo "  - Python Environment: $PYTHON_ENV_TYPE"
echo "  - Ansible Version: $(ansible --version | head -1)"
echo "  - SSH Key: $SSH_KEY_ABSOLUTE"
