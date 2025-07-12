#!/bin/bash
# Test script to verify Ansible environment setup and deployment readiness

echo "🧪 Testing Ansible Environment for Deployment"
echo "=============================================="

# Check if we're in the right directory
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "❌ Not in repository root. Please run from terraform-aws-ansible directory"
    exit 1
fi

# Test 1: Check Python 3
echo "🔍 Test 1: Python 3 availability"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ $PYTHON_VERSION"
else
    echo "❌ Python 3 not found"
    exit 1
fi

# Test 2: Check Ansible
echo "🔍 Test 2: Ansible availability"
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 || echo "unknown")
    echo "✅ $ANSIBLE_VERSION"
else
    echo "❌ Ansible not found"
    exit 1
fi

# Test 3: Check virtual environment
echo "🔍 Test 3: Virtual environment check"
if [ -d ~/.ansible-venv ]; then
    echo "✅ Ansible virtual environment found at ~/.ansible-venv"
    source ~/.ansible-venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "ℹ️  No virtual environment found (using global Python)"
fi

# Test 4: Check critical Python modules
echo "🔍 Test 4: Critical Python modules"
MISSING_MODULES=()

# Function to check module
check_module() {
    local module=$1
    if python3 -c "import $module" 2>/dev/null; then
        echo "✅ $module: Available"
    else
        echo "❌ $module: Missing"
        MISSING_MODULES+=("$module")
    fi
}

check_module "six"
check_module "boto3"
check_module "botocore"

if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    echo "❌ Missing modules: ${MISSING_MODULES[*]}"
    echo "💡 Run: ./fix-ansible.sh to fix this"
    exit 1
fi

# Test 5: Check Ansible version compatibility
echo "🔍 Test 5: Ansible version compatibility"
ANSIBLE_VER=$(ansible --version 2>/dev/null | head -1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
if [[ "$ANSIBLE_VER" =~ ^2\.[0-9]\. ]]; then
    echo "⚠️  Ansible version $ANSIBLE_VER is old, may cause issues"
    echo "💡 Run: ./fix-ansible.sh to upgrade"
elif [[ "$ANSIBLE_VER" == "unknown" ]]; then
    echo "❌ Cannot determine Ansible version"
    exit 1
else
    echo "✅ Ansible version $ANSIBLE_VER is compatible"
fi

# Test 6: Test basic Ansible functionality
echo "🔍 Test 6: Basic Ansible functionality"
if ansible --version &> /dev/null; then
    echo "✅ Ansible basic command works"
else
    echo "❌ Ansible basic command failed"
    exit 1
fi

# Test 7: Test localhost ping
echo "🔍 Test 7: Ansible localhost connection"
if ansible localhost -m ping &> /dev/null; then
    echo "✅ Ansible localhost ping successful"
else
    echo "⚠️  Ansible localhost ping failed (SSH setup may be needed)"
fi

# Test 8: Check AWS CLI
echo "🔍 Test 8: AWS CLI availability"
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | head -1)
    echo "✅ $AWS_VERSION"
else
    echo "❌ AWS CLI not found"
    exit 1
fi

# Test 9: Check AWS credentials
echo "🔍 Test 9: AWS credentials"
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "✅ AWS credentials valid (Account: $ACCOUNT_ID)"
else
    echo "❌ AWS credentials not configured or invalid"
    echo "💡 Run: aws configure"
    exit 1
fi

# Test 10: Check file structure
echo "🔍 Test 10: Project structure"
REQUIRED_FILES=(
    "terraform/main.tf"
    "terraform/variables.tf"
    "ansible/inventory/hosts.ini"
    "ansible/playbooks/site.yml"
    "ansible/ansible.cfg"
    "deploy.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file: Found"
    else
        echo "❌ $file: Missing"
        exit 1
    fi
done

# Test 11: Check SSH key parameter handling
echo "🔍 Test 11: SSH key parameter handling"
if [ -f "wtv.pem" ]; then
    echo "✅ SSH key 'wtv.pem' found in current directory"
elif [ -f "../wtv.pem" ]; then
    echo "✅ SSH key 'wtv.pem' found in parent directory"
else
    echo "⚠️  SSH key 'wtv.pem' not found"
    echo "💡 You'll need to provide the SSH key path when running deploy.sh"
fi

# Test 12: Test deployment script availability
echo "🔍 Test 12: Deployment script"
if [ -f "deploy.sh" ] && [ -x "deploy.sh" ]; then
    echo "✅ deploy.sh is executable"
else
    echo "❌ deploy.sh is not executable"
    echo "💡 Run: chmod +x deploy.sh"
    exit 1
fi

echo ""
echo "🎉 Environment Test Complete"
echo "============================"
echo "✅ All critical tests passed"
echo "✅ Python 3: Available"
echo "✅ Ansible: Available and compatible"
echo "✅ AWS CLI: Available with valid credentials"
echo "✅ Project structure: Complete"
echo ""
echo "🚀 Ready for deployment!"
echo "Usage: ./deploy.sh <path-to-ssh-key>"
echo "Example: ./deploy.sh wtv.pem"
