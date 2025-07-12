# PowerShell SSH Test Script for Terraform-deployed EC2 instance
# Usage: .\test_ssh.ps1 <key_file>

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyFile
)

# Check if we're in the terraform directory
if (-not (Test-Path "main.tf")) {
    Write-Host "Error: Please run this script from the terraform directory" -ForegroundColor Red
    exit 1
}

# Get the public IP from Terraform output
Write-Host "Getting public IP from Terraform output..." -ForegroundColor Yellow
try {
    $PublicIP = terraform output -raw instance_public_ip 2>$null
    if ([string]::IsNullOrEmpty($PublicIP)) {
        throw "Empty output"
    }
} catch {
    Write-Host "Error: Could not get public IP from Terraform output" -ForegroundColor Red
    Write-Host "Make sure you have run 'terraform apply' first" -ForegroundColor Red
    exit 1
}

Write-Host "Public IP: $PublicIP" -ForegroundColor Green
Write-Host "Key file: $KeyFile" -ForegroundColor Green
Write-Host ""

# Check key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "Error: Key file not found: $KeyFile" -ForegroundColor Red
    exit 1
}

Write-Host "Testing SSH connection to $PublicIP..." -ForegroundColor Yellow
Write-Host "Note: Make sure your key file has correct permissions" -ForegroundColor Yellow
Write-Host ""

# Test SSH connection
$SSHCommand = "ssh -i `"$KeyFile`" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$PublicIP `"echo 'SSH connection successful! Ubuntu version:' && lsb_release -d`""

try {
    Invoke-Expression $SSHCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ SSH connection test passed!" -ForegroundColor Green
        Write-Host "You can now SSH to the instance with:" -ForegroundColor Green
        Write-Host "ssh -i `"$KeyFile`" ubuntu@$PublicIP" -ForegroundColor Cyan
    } else {
        throw "SSH connection failed"
    }
} catch {
    Write-Host ""
    Write-Host "❌ SSH connection failed. Check:" -ForegroundColor Red
    Write-Host "1. Security group allows SSH (port 22) from your IP" -ForegroundColor Red
    Write-Host "2. Key file path is correct and has proper permissions" -ForegroundColor Red
    Write-Host "3. Public IP is correct: $PublicIP" -ForegroundColor Red
    Write-Host "4. Instance is in running state" -ForegroundColor Red
    Write-Host "5. You're running this from the terraform directory" -ForegroundColor Red
    Write-Host "6. SSH client is installed and available in PATH" -ForegroundColor Red
}
