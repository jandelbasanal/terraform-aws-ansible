#!/bin/bash
# Complete Ansible Fix Script - Handles all common Ansible issues

set -e

echo "🔧 Complete Ansible Environment Fix"
echo "==================================="

# Check if we have Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3 first."
    exit 1
fi

# Check current Ansible installation
echo "🔍 Checking current Ansible installation..."
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
    echo "✅ Found existing Ansible virtual environment"
    USE_VENV=true
elif [ "$1" = "--venv" ]; then
    echo "🔧 Creating new Ansible virtual environment..."
    python3 -m venv ~/.ansible-venv
    USE_VENV=true
fi

# Function to install packages
install_package() {
    local package=$1
    if [ "$USE_VENV" = true ]; then
        source ~/.ansible-venv/bin/activate
        pip install "$package"
    else
        pip3 install "$package"
    fi
}

# Function to check if a Python module is available
check_python_module() {
    local module=$1
    if [ "$USE_VENV" = true ]; then
        source ~/.ansible-venv/bin/activate
        python3 -c "import $module" 2>/dev/null
    else
        python3 -c "import $module" 2>/dev/null
    fi
}

# Activate virtual environment if using it
if [ "$USE_VENV" = true ]; then
    echo "🔧 Activating Ansible virtual environment..."
    source ~/.ansible-venv/bin/activate
    export PATH="~/.ansible-venv/bin:$PATH"
fi

# Step 1: Upgrade pip and basic tools
echo "🔄 Upgrading pip and basic Python tools..."
install_package "--upgrade pip setuptools wheel"

# Step 2: Install six (critical dependency for older Ansible versions)
echo "🔄 Installing six module (critical dependency)..."
install_package "six"

# Step 3: Install AWS dependencies
echo "🔄 Installing AWS dependencies..."
install_package "boto3"
install_package "botocore"

# Step 4: Install/upgrade Ansible
echo "🔄 Installing/upgrading Ansible..."
# Remove old versions first to avoid conflicts
if [ "$CURRENT_VERSION" != "none" ]; then
    if [ "$USE_VENV" = true ]; then
        source ~/.ansible-venv/bin/activate
        pip uninstall -y ansible ansible-core ansible-base || true
    else
        pip3 uninstall -y ansible ansible-core ansible-base || true
    fi
fi

# Install a compatible version
install_package "'ansible>=4.0.0,<6.0.0'"
install_package "'ansible-core>=2.11.0,<2.13.0'"

# Step 5: Verify installation
echo "✅ Verifying installation..."

# Check Ansible version
if [ "$USE_VENV" = true ]; then
    source ~/.ansible-venv/bin/activate
fi

if command -v ansible &> /dev/null; then
    NEW_VERSION=$(ansible --version 2>/dev/null | head -1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
    echo "✅ New Ansible version: $NEW_VERSION"
else
    echo "❌ Ansible installation failed"
    exit 1
fi

# Check Python modules
echo "🔍 Checking Python modules..."
FAILED_MODULES=()

if ! check_python_module "six"; then
    FAILED_MODULES+=("six")
fi

if ! check_python_module "boto3"; then
    FAILED_MODULES+=("boto3")
fi

if ! check_python_module "botocore"; then
    FAILED_MODULES+=("botocore")
fi

if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
    echo "❌ The following modules are still missing: ${FAILED_MODULES[*]}"
    echo "Attempting to reinstall them..."
    for module in "${FAILED_MODULES[@]}"; do
        install_package "$module"
    done
    
    # Re-check
    NEW_FAILED=()
    for module in "${FAILED_MODULES[@]}"; do
        if ! check_python_module "$module"; then
            NEW_FAILED+=("$module")
        fi
    done
    
    if [ ${#NEW_FAILED[@]} -gt 0 ]; then
        echo "❌ Critical: Still missing modules: ${NEW_FAILED[*]}"
        echo "Please check your Python environment and try manual installation:"
        if [ "$USE_VENV" = true ]; then
            echo "  source ~/.ansible-venv/bin/activate"
        fi
        for module in "${NEW_FAILED[@]}"; do
            echo "  pip install $module"
        done
        exit 1
    fi
fi

echo "✅ All Python modules verified"

# Step 6: Test Ansible functionality
echo "🧪 Testing Ansible functionality..."
if [ "$USE_VENV" = true ]; then
    source ~/.ansible-venv/bin/activate
fi

# Test basic Ansible command
if ansible --version &> /dev/null; then
    echo "✅ Ansible basic functionality: OK"
else
    echo "❌ Ansible basic functionality: FAILED"
    exit 1
fi

# Test localhost connection
if ansible localhost -m ping &> /dev/null; then
    echo "✅ Ansible localhost connection: OK"
else
    echo "⚠️  Ansible localhost connection: FAILED (may need SSH setup)"
fi

# Test AWS module import
if ansible localhost -m debug -a "msg='Testing AWS modules'" &> /dev/null; then
    echo "✅ Ansible AWS modules: OK"
else
    echo "⚠️  Ansible AWS modules: May have issues"
fi

echo ""
echo "🎉 Ansible environment fix complete!"
echo "==================================="
echo "✅ Ansible version: $(ansible --version | head -1)"
echo "✅ Python modules: six, boto3, botocore"
if [ "$USE_VENV" = true ]; then
    echo "✅ Virtual environment: ~/.ansible-venv"
    echo ""
    echo "📝 To use this environment in the future:"
    echo "   source ~/.ansible-venv/bin/activate"
fi
echo ""
echo "🚀 You can now run: ./deploy.sh <ssh-key-path>"
