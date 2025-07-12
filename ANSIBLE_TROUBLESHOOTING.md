# Ansible Environment Troubleshooting Guide

This guide helps you resolve common Ansible issues when deploying the WordPress infrastructure.

## Common Issues and Solutions

### 1. Missing `six` Module Error

**Error Message:**
```
ModuleNotFoundError: No module named 'six'
```

**Solution:**
The deployment script (`deploy.sh`) now automatically detects and fixes this issue. If you still encounter problems:

```bash
# Quick fix
./fix-ansible.sh

# Complete fix (recommended)
./fix-ansible-complete.sh
```

### 2. Old Ansible Version (2.9.x)

**Error Message:**
```
Ansible version 2.9.x detected
```

**Solution:**
The deployment script automatically upgrades Ansible to a compatible version. Manual fix:

```bash
# If using virtual environment
source ~/.ansible-venv/bin/activate
pip install --upgrade 'ansible>=4.0.0,<6.0.0'
pip install --upgrade 'ansible-core>=2.11.0,<2.13.0'

# If using global Python
pip3 install --upgrade 'ansible>=4.0.0,<6.0.0'
pip3 install --upgrade 'ansible-core>=2.11.0,<2.13.0'
```

### 3. Missing AWS Modules (boto3/botocore)

**Error Message:**
```
ModuleNotFoundError: No module named 'boto3'
```

**Solution:**
```bash
# If using virtual environment
source ~/.ansible-venv/bin/activate
pip install boto3 botocore

# If using global Python
pip3 install boto3 botocore
```

### 4. SSH Key Path Issues

**Error Message:**
```
SSH key not found at wtv.pem
```

**Solution:**
The deployment script now handles both relative and absolute paths. Use:

```bash
# With relative path
./deploy.sh wtv.pem

# With absolute path
./deploy.sh /full/path/to/wtv.pem

# With path in different directory
./deploy.sh ../wtv.pem
```

## Available Fix Scripts

### 1. `deploy.sh` (Recommended)
- **Purpose**: Main deployment script with built-in fixes
- **Usage**: `./deploy.sh <ssh-key-path>`
- **Features**: 
  - Automatic Ansible version detection and upgrade
  - Automatic dependency installation
  - SSH key path resolution
  - Comprehensive error handling

### 2. `fix-ansible.sh`
- **Purpose**: Quick fix for common Ansible issues
- **Usage**: `./fix-ansible.sh`
- **Features**:
  - Fixes missing Python dependencies
  - Upgrades old Ansible versions
  - Updates SSH key paths in inventory

### 3. `fix-ansible-complete.sh`
- **Purpose**: Complete Ansible environment setup
- **Usage**: `./fix-ansible-complete.sh` or `./fix-ansible-complete.sh --venv`
- **Features**:
  - Full Ansible environment rebuild
  - Virtual environment support
  - Comprehensive testing

### 4. `test-deployment-readiness.sh`
- **Purpose**: Test if environment is ready for deployment
- **Usage**: `./test-deployment-readiness.sh`
- **Features**:
  - Checks all dependencies
  - Validates configuration
  - Tests connectivity

## Environment Setup Options

### Option 1: Global Python (Default)
```bash
pip3 install ansible boto3 botocore six
```

### Option 2: Virtual Environment (Recommended)
```bash
python3 -m venv ~/.ansible-venv
source ~/.ansible-venv/bin/activate
pip install ansible boto3 botocore six
```

The deployment script automatically detects and uses virtual environments.

## Deployment Workflow

1. **Test Environment**:
   ```bash
   ./test-deployment-readiness.sh
   ```

2. **Fix Issues (if any)**:
   ```bash
   ./fix-ansible.sh
   ```

3. **Deploy**:
   ```bash
   ./deploy.sh <ssh-key-path>
   ```

## Manual Troubleshooting

### Check Python Modules
```bash
python3 -c "import six, boto3, botocore; print('All modules available')"
```

### Check Ansible Version
```bash
ansible --version
```

### Check Virtual Environment
```bash
ls -la ~/.ansible-venv/
```

### Test Ansible Connection
```bash
ansible localhost -m ping
```

## Version Compatibility

| Component | Minimum Version | Recommended Version |
|-----------|-----------------|-------------------|
| Python    | 3.6             | 3.8+             |
| Ansible   | 4.0.0           | 4.0.0 - 5.x      |
| ansible-core | 2.11.0       | 2.11.0 - 2.12.x  |
| boto3     | 1.17.0          | Latest           |
| botocore  | 1.20.0          | Latest           |
| six       | 1.15.0          | Latest           |

## Getting Help

If you encounter issues not covered here:

1. Run the test script: `./test-deployment-readiness.sh`
2. Check the specific error messages
3. Try the complete fix: `./fix-ansible-complete.sh`
4. Check the deployment logs for detailed error information

## Prevention

To avoid future issues:

1. **Use Virtual Environments**: Isolates dependencies
2. **Regular Updates**: Keep dependencies current
3. **Test Before Deploy**: Run readiness tests
4. **Use Absolute Paths**: For SSH keys and other files

The deployment script is now designed to be self-healing and should handle most common issues automatically.
