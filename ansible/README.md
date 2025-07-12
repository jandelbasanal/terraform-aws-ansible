# Ansible WordPress Configuration

This directory contains Ansible playbooks and roles for deploying WordPress on AWS EC2 instances created by Terraform.

## Structure

```
ansible/
├── ansible.cfg                # Ansible configuration
├── requirements.txt           # Python dependencies
├── inventory/                 # Inventory files
│   └── hosts.ini             # Dynamic inventory (auto-generated)
├── playbooks/                # Ansible playbooks
│   └── site.yml              # WordPress deployment playbook
└── roles/                    # Ansible roles
    ├── common/               # Common system configuration
    ├── mysql/                # MySQL database setup
    ├── apache/               # Apache web server setup
    ├── php/                  # PHP configuration
    └── wordpress/            # WordPress installation
```

## Prerequisites

- Python 3.8+
- Ansible >= 6.0.0
- AWS EC2 instance with Ubuntu 24.04 LTS
- SSH access to the EC2 instance
- Terraform-deployed infrastructure

## Installation

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Verify Ansible installation:
   ```bash
   ansible --version
   ```

## Usage

### Method 1: Automated Deployment (Recommended)

Use the integrated deployment script from the project root:

```bash
# From project root
./deploy.sh /path/to/your/ssh-key.pem
```

Or on Windows:
```powershell
# From project root
.\deploy.ps1 C:\path\to\your\ssh-key.pem
```

### Method 2: Manual Deployment

1. **Navigate to ansible directory**:
   ```bash
   cd ansible
   ```

2. **Configure inventory** (replace with your EC2 public IP):
   ```bash
   cat > inventory/hosts.ini << EOF
   [wordpress]
   YOUR_EC2_PUBLIC_IP ansible_ssh_private_key_file=/path/to/your/key.pem
   
   [wordpress:vars]
   ansible_user=ubuntu
   ansible_ssh_common_args='-o StrictHostKeyChecking=no'
   EOF
   ```

3. **Update ansible.cfg** with your SSH key path:
   ```ini
   [defaults]
   private_key_file = /path/to/your/key.pem
   ```

4. **Test connectivity**:
   ```bash
   ansible all -i inventory/hosts.ini -m ping
   ```

5. **Deploy WordPress**:
   ```bash
   ansible-playbook -i inventory/hosts.ini playbooks/site.yml
   ```

## WordPress Configuration

The playbook installs and configures:

- **MySQL Database**: WordPress database with dedicated user
- **Apache Web Server**: Virtual host configuration with security headers
- **PHP**: Latest PHP with required extensions
- **WordPress**: Latest version with WP-CLI integration

### Default Settings

| Component | Setting | Value |
|-----------|---------|-------|
| Database Name | wordpress | wordpress |
| Database User | wordpress | wordpress |
| Admin Username | admin | admin |
| Admin Password | admin123! | **Change immediately** |
| Admin Email | admin@example.com | Update in playbook |

### Security Features

- UFW firewall configured (ports 22, 80, 443)
- MySQL root password protection
- Apache security headers
- WordPress security keys auto-generated
- File permissions properly set

## Customization

### Variables

Edit `playbooks/site.yml` to customize:

```yaml
vars:
  mysql_root_password: "your_secure_password"
  mysql_wordpress_password: "your_db_password"
  wordpress_title: "Your Site Title"
  wordpress_admin_user: "your_admin"
  wordpress_admin_password: "your_admin_password"
  wordpress_admin_email: "your_email@domain.com"
```

### Using Ansible Vault

For production, use Ansible Vault to encrypt sensitive data:

```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml

# Add encrypted variables
vault_mysql_root_password: "secure_password"
vault_mysql_wordpress_password: "secure_db_password"
vault_wordpress_admin_password: "secure_admin_password"

# Run playbook with vault
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-vault-pass
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Check security group allows SSH (port 22)
   - Verify SSH key permissions: `chmod 600 your-key.pem`
   - Ensure correct username (ubuntu for Ubuntu instances)

2. **MySQL Connection Issues**:
   - Check MySQL service: `sudo systemctl status mysql`
   - Verify database user: `mysql -u root -p`

3. **Apache Issues**:
   - Check Apache status: `sudo systemctl status apache2`
   - View error logs: `sudo tail -f /var/log/apache2/error.log`

4. **WordPress Issues**:
   - Check file permissions: `ls -la /var/www/html/`
   - Verify PHP modules: `php -m`

### Logs

- **Apache Access**: `/var/log/apache2/wordpress_access.log`
- **Apache Error**: `/var/log/apache2/wordpress_error.log`
- **MySQL**: `/var/log/mysql/error.log`
- **Ansible**: Run with `-v` flag for verbose output

## Post-Deployment

### Immediate Actions

1. **Change admin password** via WordPress admin panel
2. **Update WordPress** core, themes, and plugins
3. **Install SSL certificate** (Let's Encrypt recommended)
4. **Configure backups** (database and files)
5. **Set up monitoring** (optional)

### WordPress Admin Access

- **URL**: `http://YOUR_EC2_IP/wp-admin`
- **Username**: `admin` (or your custom username)
- **Password**: `admin123!` (change immediately)

### SSH Management

```bash
# Connect to server
ssh -i /path/to/key.pem ubuntu@YOUR_EC2_IP

# Check services
sudo systemctl status apache2 mysql

# View logs
sudo tail -f /var/log/apache2/error.log

# Restart services
sudo systemctl restart apache2
sudo systemctl restart mysql
```

## Integration with Terraform

This Ansible configuration is designed to work with the Terraform infrastructure in the `../terraform` directory:

- Uses EC2 instance created by Terraform
- Integrates with security groups for HTTP/HTTPS access
- Leverages Terraform outputs for dynamic inventory
