# System Preparation and Version Management

## Overview

The enhanced Ansible playbook now includes comprehensive system preparation and automatic detection/installation of the latest software versions. This ensures your WordPress deployment runs on the most current and secure software stack.

## Features

### 🔍 System Compatibility Checks
- **OS Version Verification**: Ensures Ubuntu 20.04+ or Debian 10+
- **Architecture Detection**: Validates system architecture
- **Resource Assessment**: Checks available memory and disk space
- **Security Status**: Reviews firewall and update status

### 📦 Automatic Software Detection
- **PHP Detection**: Identifies current PHP version and modules
- **MySQL Detection**: Checks existing MySQL/MariaDB installation
- **Apache Detection**: Verifies Apache web server status

### 🔄 Latest Version Installation
- **PHP 8.3**: Installs latest stable PHP with all required WordPress modules
- **MySQL 8.0**: Sets up latest MySQL server with optimal configuration
- **Apache 2.4**: Configures latest Apache with security best practices

### 🛠️ Smart Upgrade Logic
- **Version Comparison**: Only upgrades when beneficial
- **Compatibility Checks**: Ensures smooth transitions
- **Backup Protection**: Creates backups before major changes

## Usage

### Quick System Check
```bash
# Check remote system compatibility and current software
./check-remote-system.sh ~/.ssh/your-key.pem
```

### Pre-Deployment Validation
```bash
# Comprehensive pre-deployment validation with interactive confirmation
./validate-deployment.sh ~/.ssh/your-key.pem
```

### Enhanced Deployment
```bash
# Full deployment with system preparation
./deploy.sh ~/.ssh/your-key.pem
```

### Testing Only
```bash
# Test deployment with enhanced system prep
./test-ansible.sh ~/.ssh/your-key.pem
```

## What Gets Checked and Installed

### System Requirements
- ✅ **OS**: Ubuntu 20.04+ or Debian 10+
- ✅ **Memory**: Minimum 512MB (1GB+ recommended)
- ✅ **Disk**: 5GB+ available space
- ✅ **Architecture**: x86_64 or ARM64

### Software Stack
- 🐘 **PHP 8.3** with modules:
  - mysql, curl, gd, mbstring, xml, xmlrpc
  - soap, intl, zip, fpm
- 🗄️ **MySQL 8.0** with:
  - Optimized configuration for WordPress
  - Secure default settings
  - Performance tuning
- 🌐 **Apache 2.4** with:
  - mod_rewrite enabled
  - Security headers configured
  - Virtual host setup

### Security Enhancements
- 🔐 **UFW Firewall**: Configured with WordPress-specific rules
- 🛡️ **Security Updates**: Automatically installed
- 🔒 **File Permissions**: Properly configured for WordPress
- 🚫 **Default Passwords**: Changed to secure alternatives

## Configuration Details

### PHP Configuration
The playbook automatically configures PHP with WordPress-optimized settings:
```ini
upload_max_filesize = 64M
post_max_size = 64M
memory_limit = 256M
max_execution_time = 300
max_input_vars = 3000
```

### MySQL Configuration
MySQL is configured with:
- Secure root password
- WordPress-specific database and user
- Optimized performance settings
- UTF8 character set support

### System Optimizations
- **Swap File**: Created automatically if memory < 2GB
- **Timezone**: Set to UTC for consistency
- **Package Updates**: Security updates applied
- **Essential Tools**: curl, wget, git, unzip installed

## Troubleshooting

### Common Issues

#### OS Compatibility Error
```
TASK [system-prep : Check OS compatibility] FAILED!
```
**Solution**: Ensure you're using Ubuntu 20.04+ or Debian 10+

#### Low Memory Warning
```
WARNING: Low system resources detected
```
**Solution**: Consider upgrading to an instance with more RAM

#### Repository Access Issues
```
Failed to add PHP repository
```
**Solution**: Check internet connectivity and DNS resolution

#### Version Conflicts
```
PHP upgrade needed but conflicts detected
```
**Solution**: Review existing PHP installations and remove conflicting packages

### Debug Commands

```bash
# Check system info remotely
ansible all -i ansible/inventory/hosts.ini -m setup -a "filter=ansible_distribution*"

# Test PHP installation
ansible all -i ansible/inventory/hosts.ini -m shell -a "php --version"

# Check MySQL status
ansible all -i ansible/inventory/hosts.ini -m shell -a "systemctl status mysql"

# Verify Apache configuration
ansible all -i ansible/inventory/hosts.ini -m shell -a "apache2ctl -t"
```

## Advanced Usage

### Skip System Preparation
If you want to skip system preparation (not recommended):
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --skip-tags "system-prep"
```

### Run Only System Preparation
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --tags "system-prep"
```

### Verbose Output for Debugging
```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -vvv
```

## Benefits

1. **🔒 Security**: Latest software versions with security patches
2. **⚡ Performance**: Optimized configurations for WordPress
3. **🛠️ Reliability**: Thorough compatibility and resource checks
4. **🚀 Automation**: Zero manual intervention required
5. **📊 Visibility**: Comprehensive reporting of system status
6. **🔄 Flexibility**: Handles various starting system states

The enhanced system preparation ensures your WordPress deployment starts with a solid, secure, and optimized foundation regardless of the initial server state.
