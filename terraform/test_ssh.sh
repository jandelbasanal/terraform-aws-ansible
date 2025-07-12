#!/bin/bash
# SSH Test Script for Terraform-deployed EC2 instance
# Usage: ./test_ssh.sh <key_file>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <key_file>"
    echo "Example: $0 ~/.ssh/your-key.pem"
    exit 1
fi

KEY_FILE=$1

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    echo "Error: Please run this script from the terraform directory"
    exit 1
fi

# Get the public IP from Terraform output
echo "Getting public IP from Terraform output..."
PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null)

if [ -z "$PUBLIC_IP" ]; then
    echo "Error: Could not get public IP from Terraform output"
    echo "Make sure you have run 'terraform apply' first"
    exit 1
fi

echo "Public IP: $PUBLIC_IP"
echo "Key file: $KEY_FILE"
echo ""

# Check key file permissions
if [ ! -f "$KEY_FILE" ]; then
    echo "Error: Key file not found: $KEY_FILE"
    exit 1
fi

# Set proper permissions if needed
chmod 400 "$KEY_FILE"

echo "Testing SSH connection to $PUBLIC_IP..."
echo "Make sure your key file has correct permissions: chmod 400 $KEY_FILE"
echo ""

# Test SSH connection
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@"$PUBLIC_IP" 'echo "SSH connection successful! Ubuntu version:" && lsb_release -d'

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSH connection test passed!"
    echo "You can now SSH to the instance with:"
    echo "ssh -i $KEY_FILE ubuntu@$PUBLIC_IP"
else
    echo ""
    echo "❌ SSH connection failed. Check:"
    echo "1. Security group allows SSH (port 22) from your IP"
    echo "2. Key file path is correct and has proper permissions (chmod 400)"
    echo "3. Public IP is correct: $PUBLIC_IP"
    echo "4. Instance is in running state"
    echo "5. You're running this from the terraform directory"
fi
