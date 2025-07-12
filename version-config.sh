#!/bin/bash
# Version requirements configuration
# This file centralizes all version requirements for the project

# Terraform version
TERRAFORM_VERSION="1.12.2"

# AWS CLI version (minimum)
AWS_CLI_VERSION="2.0.0"

# Ansible version (minimum)
ANSIBLE_VERSION="6.0.0"

# Python version (minimum)
PYTHON_VERSION="3.8"

# Ubuntu version (minimum)
UBUNTU_VERSION="22.04"

# Download URLs and checksums
TERRAFORM_BASE_URL="https://releases.hashicorp.com/terraform"
AWS_CLI_BASE_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

# Function to get architecture
get_arch() {
    case "$(uname -m)" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64) echo "arm64" ;;
        *) echo "amd64" ;;
    esac
}

# Function to get OS
get_os() {
    case "$(uname -s)" in
        Linux) echo "linux" ;;
        Darwin) echo "darwin" ;;
        *) echo "linux" ;;
    esac
}

# Function to build Terraform download URL
get_terraform_download_url() {
    local version=$1
    local os=$(get_os)
    local arch=$(get_arch)
    echo "${TERRAFORM_BASE_URL}/${version}/terraform_${version}_${os}_${arch}.zip"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Invalid version format: $version"
        return 1
    fi
    return 0
}

# Function to compare versions
version_greater_equal() {
    local version1=$1
    local version2=$2
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    
    # Fill empty fields with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    
    # Compare each component
    for ((i=0; i<${#ver1[@]}; i++)); do
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 0
        elif ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 1
        fi
    done
    
    return 0
}

# Export all variables for use in other scripts
export TERRAFORM_VERSION
export AWS_CLI_VERSION
export ANSIBLE_VERSION
export PYTHON_VERSION
export UBUNTU_VERSION
export TERRAFORM_BASE_URL
export AWS_CLI_BASE_URL
