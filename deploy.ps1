# PowerShell Terraform + Ansible WordPress Deployment Script

param(
    [Parameter(Mandatory=$true)]
    [string]$SSHKeyPath
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Terraform + Ansible WordPress Deployment" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green

# Check if we're in the correct directory
if (-not (Test-Path "terraform") -or -not (Test-Path "ansible")) {
    Write-Host "❌ Error: Please run this script from the repository root" -ForegroundColor Red
    Write-Host "Expected structure: terraform/ and ansible/ directories" -ForegroundColor Red
    exit 1
}

# Check dependencies
Write-Host "🔍 Checking dependencies..." -ForegroundColor Yellow

# Check Terraform
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Terraform not found. Please install Terraform first." -ForegroundColor Red
    exit 1
}

# Check Ansible
if (-not (Get-Command ansible -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Ansible not found. Please install Ansible first." -ForegroundColor Red
    Write-Host "Install with: pip install ansible" -ForegroundColor Red
    exit 1
}

# Validate SSH key exists
if (-not (Test-Path $SSHKeyPath)) {
    Write-Host "❌ Error: SSH key not found at $SSHKeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dependencies check passed" -ForegroundColor Green
Write-Host "✅ SSH key found: $SSHKeyPath" -ForegroundColor Green

# Step 1: Deploy infrastructure with Terraform
Write-Host ""
Write-Host "🏗️  Step 1: Deploying AWS infrastructure with Terraform..." -ForegroundColor Yellow
Set-Location terraform

# Check if terraform.tfvars exists
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "❌ Error: terraform.tfvars not found" -ForegroundColor Red
    Write-Host "Please create terraform.tfvars from terraform.tfvars.example" -ForegroundColor Red
    exit 1
}

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Plan deployment
Write-Host "Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan

# Apply deployment
Write-Host "Applying Terraform deployment..." -ForegroundColor Yellow
terraform apply -auto-approve

# Get the public IP
try {
    $PublicIP = terraform output -raw instance_public_ip
    if ([string]::IsNullOrEmpty($PublicIP)) {
        throw "Empty IP"
    }
} catch {
    Write-Host "❌ Error: Could not get public IP from Terraform output" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "✅ EC2 Public IP: $PublicIP" -ForegroundColor Green

# Step 2: Wait for EC2 instance to be ready
Write-Host ""
Write-Host "⏳ Step 2: Waiting for EC2 instance to be ready..." -ForegroundColor Yellow
Set-Location ..

# Wait for SSH to be available
Write-Host "Waiting for SSH to be available on $PublicIP..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 1

while ($attempt -le $maxAttempts) {
    try {
        $result = ssh -i "$SSHKeyPath" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$PublicIP "echo 'SSH Ready'" 2>$null
        if ($result -eq "SSH Ready") {
            Write-Host "✅ SSH connection established!" -ForegroundColor Green
            break
        }
    } catch {
        # Continue trying
    }
    
    Write-Host "Attempt $attempt/$maxAttempts - SSH not ready yet, waiting 10 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    $attempt++
}

if ($attempt -gt $maxAttempts) {
    Write-Host "❌ Error: SSH connection timeout after $maxAttempts attempts" -ForegroundColor Red
    exit 1
}

# Step 3: Configure dynamic inventory
Write-Host ""
Write-Host "📝 Step 3: Configuring Ansible inventory..." -ForegroundColor Yellow
Set-Location ansible

# Update inventory with the actual IP
$inventoryContent = @"
[wordpress]
$PublicIP ansible_ssh_private_key_file=$SSHKeyPath

[wordpress:vars]
ansible_user=ubuntu
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"@

$inventoryContent | Out-File -FilePath "inventory/hosts.ini" -Encoding UTF8

# Update ansible.cfg with the correct key path
$ansibleCfg = Get-Content "ansible.cfg" -Raw
$ansibleCfg = $ansibleCfg -replace "private_key_file = ~/.ssh/your-key.pem", "private_key_file = $SSHKeyPath"
$ansibleCfg | Out-File -FilePath "ansible.cfg" -Encoding UTF8

Write-Host "✅ Inventory configured with IP: $PublicIP" -ForegroundColor Green

# Step 4: Deploy WordPress with Ansible
Write-Host ""
Write-Host "📦 Step 4: Deploying WordPress with Ansible..." -ForegroundColor Yellow

# Test connectivity first
Write-Host "Testing Ansible connectivity..." -ForegroundColor Yellow
$pingResult = ansible all -i inventory/hosts.ini -m ping

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ansible connectivity test passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Ansible connectivity test failed!" -ForegroundColor Red
    exit 1
}

# Run the WordPress playbook
Write-Host "Running WordPress deployment playbook..." -ForegroundColor Yellow
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "🎉 WordPress deployment completed successfully!" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Access your WordPress site:" -ForegroundColor Cyan
    Write-Host "   Site URL: http://$PublicIP" -ForegroundColor White
    Write-Host "   Admin URL: http://$PublicIP/wp-admin" -ForegroundColor White
    Write-Host ""
    Write-Host "🔑 Default credentials:" -ForegroundColor Cyan
    Write-Host "   Username: admin" -ForegroundColor White
    Write-Host "   Password: admin123!" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  Security Notes:" -ForegroundColor Yellow
    Write-Host "   - Change the default admin password immediately" -ForegroundColor White
    Write-Host "   - Consider setting up SSL/TLS certificates" -ForegroundColor White
    Write-Host "   - Update WordPress and plugins regularly" -ForegroundColor White
    Write-Host "   - Review security group settings" -ForegroundColor White
    Write-Host ""
    Write-Host "🛠️  Management:" -ForegroundColor Cyan
    Write-Host "   - SSH to server: ssh -i $SSHKeyPath ubuntu@$PublicIP" -ForegroundColor White
    Write-Host "   - View logs: tail -f /var/log/apache2/error.log" -ForegroundColor White
    Write-Host "   - Restart services: sudo systemctl restart apache2" -ForegroundColor White
} else {
    Write-Host "❌ WordPress deployment failed!" -ForegroundColor Red
    exit 1
}
