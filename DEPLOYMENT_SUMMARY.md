# WordPress Deployment Summary

## What Gets Deployed

### AWS Infrastructure (Terraform)
- **VPC**: 10.10.0.0/16 with DNS support
- **Subnets**: 2 public subnets across AZs
- **Security Group**: SSH (22), HTTP (80), HTTPS (443) access
- **EC2 Instance**: Ubuntu 24.04 LTS t2.micro
- **Internet Gateway**: Public internet access

### WordPress Stack (Ansible)
- **Operating System**: Ubuntu 24.04 LTS
- **Web Server**: Apache 2.4 with virtual host
- **Database**: MySQL 8.0 with WordPress database
- **PHP**: PHP 8.1 with required extensions
- **WordPress**: Latest version with WP-CLI
- **Security**: UFW firewall, secure file permissions

## Default Credentials

### WordPress Admin
- **URL**: http://YOUR_EC2_IP/wp-admin
- **Username**: admin
- **Password**: admin123! (⚠️ Change immediately)

### Database
- **Database Name**: wordpress
- **Database User**: wordpress
- **Database Password**: wordpress123! (auto-generated)

### System Access
- **SSH User**: ubuntu
- **SSH Key**: Your provided key pair

## Deployment Options

### Option 1: Automated (Recommended)
```bash
./deploy.sh /path/to/your/ssh-key.pem
```

### Option 2: Manual
```bash
# Deploy infrastructure
cd terraform
terraform init && terraform apply

# Get IP and configure Ansible
cd ../ansible
# Update inventory with EC2 IP
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

## Post-Deployment Checklist

- [ ] Change WordPress admin password
- [ ] Update WordPress core, themes, plugins
- [ ] Configure SSL certificate (Let's Encrypt)
- [ ] Set up backups (database and files)
- [ ] Review security group settings
- [ ] Configure domain name (optional)
- [ ] Set up monitoring (optional)

## Troubleshooting

### Common Issues
1. **SSH Connection Failed**: Check security group, key permissions
2. **HTTP Not Accessible**: Check security group port 80
3. **WordPress Not Loading**: Check Apache/MySQL services
4. **Database Connection Error**: Check MySQL credentials

### Useful Commands
```bash
# SSH to server
ssh -i /path/to/key.pem ubuntu@YOUR_EC2_IP

# Check services
sudo systemctl status apache2 mysql

# View logs
sudo tail -f /var/log/apache2/error.log

# Restart services
sudo systemctl restart apache2 mysql
```

## File Structure
```
project/
├── deploy.sh                    # Automated deployment script
├── deploy.ps1                   # Windows PowerShell version
├── validate.sh                  # Validation script
├── terraform/                   # Infrastructure code
│   ├── main.tf
│   ├── variables.tf
│   ├── modules/
│   └── terraform.tfvars.example
└── ansible/                     # Configuration code
    ├── ansible.cfg
    ├── requirements.txt
    ├── inventory/
    ├── playbooks/
    └── roles/
```

## Security Considerations

### Current Security
- UFW firewall enabled
- MySQL root password protected
- WordPress security keys auto-generated
- File permissions properly set

### Production Recommendations
- Restrict SSH access to specific IPs
- Enable SSL/TLS with Let's Encrypt
- Use strong passwords (consider Ansible Vault)
- Regular security updates
- Database backups
- Web Application Firewall (WAF)
- Monitoring and alerting

## Cost Estimation (AWS)

### Monthly Costs (approximate)
- **EC2 t2.micro**: $8.50/month
- **EBS Storage**: $1.00/month (8GB)
- **Data Transfer**: $0.00 (free tier)
- **Total**: ~$9.50/month

*Note: Costs may vary by region and usage*
