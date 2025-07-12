#!/bin/bash
# Version management script for updating required versions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_CONFIG="$SCRIPT_DIR/version-config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display current versions
show_current_versions() {
    echo -e "${BLUE}📋 Current Version Requirements:${NC}"
    echo "================================="
    
    source "$VERSION_CONFIG"
    echo -e "Terraform: ${GREEN}$TERRAFORM_VERSION${NC}"
    echo -e "AWS CLI: ${GREEN}$AWS_CLI_VERSION${NC}"
    echo -e "Ansible: ${GREEN}$ANSIBLE_VERSION${NC}"
    echo -e "Python: ${GREEN}$PYTHON_VERSION${NC}"
    echo -e "Ubuntu: ${GREEN}$UBUNTU_VERSION${NC}"
    echo ""
}

# Function to update version in config file
update_version() {
    local tool=$1
    local new_version=$2
    local var_name=""
    
    case $tool in
        "terraform") var_name="TERRAFORM_VERSION" ;;
        "aws-cli") var_name="AWS_CLI_VERSION" ;;
        "ansible") var_name="ANSIBLE_VERSION" ;;
        "python") var_name="PYTHON_VERSION" ;;
        "ubuntu") var_name="UBUNTU_VERSION" ;;
        *) echo -e "${RED}❌ Unknown tool: $tool${NC}"; return 1 ;;
    esac
    
    # Validate version format
    if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "${RED}❌ Invalid version format: $new_version${NC}"
        return 1
    fi
    
    # Update the version in the config file
    sed -i "s/^${var_name}=\".*\"/${var_name}=\"${new_version}\"/" "$VERSION_CONFIG"
    
    echo -e "${GREEN}✅ Updated $tool version to $new_version${NC}"
}

# Function to check latest versions online
check_latest_versions() {
    echo -e "${BLUE}🔍 Checking latest versions online...${NC}"
    echo "================================="
    
    # Check latest Terraform version
    echo -n "Terraform: "
    if command -v curl &> /dev/null; then
        LATEST_TERRAFORM=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep -oP '"tag_name": "v\K[0-9.]+' 2>/dev/null || echo "unknown")
        if [[ "$LATEST_TERRAFORM" != "unknown" ]]; then
            echo -e "${GREEN}$LATEST_TERRAFORM${NC}"
        else
            echo -e "${YELLOW}Could not fetch${NC}"
        fi
    else
        echo -e "${YELLOW}curl not available${NC}"
    fi
    
    # Check latest AWS CLI version
    echo -n "AWS CLI: "
    if command -v aws &> /dev/null; then
        LATEST_AWS=$(aws --version 2>&1 | grep -oP 'aws-cli/\K[0-9.]+' || echo "unknown")
        if [[ "$LATEST_AWS" != "unknown" ]]; then
            echo -e "${GREEN}$LATEST_AWS${NC}"
        else
            echo -e "${YELLOW}Could not determine${NC}"
        fi
    else
        echo -e "${YELLOW}AWS CLI not installed${NC}"
    fi
    
    # Check latest Ansible version
    echo -n "Ansible: "
    if command -v ansible &> /dev/null; then
        LATEST_ANSIBLE=$(ansible --version 2>&1 | grep -oP 'ansible \[core \K[0-9.]+' || ansible --version 2>&1 | grep -oP 'ansible \K[0-9.]+' || echo "unknown")
        if [[ "$LATEST_ANSIBLE" != "unknown" ]]; then
            echo -e "${GREEN}$LATEST_ANSIBLE${NC}"
        else
            echo -e "${YELLOW}Could not determine${NC}"
        fi
    else
        echo -e "${YELLOW}Ansible not installed${NC}"
    fi
    
    echo ""
}

# Function to update Terraform version constraint
update_terraform_constraint() {
    local version=$1
    local version_tf="$SCRIPT_DIR/terraform/version.tf"
    
    if [[ -f "$version_tf" ]]; then
        sed -i "s/required_version = \">= [0-9.]*\"/required_version = \">= $version\"/" "$version_tf"
        sed -i "s/# - Terraform: >= [0-9.]*/# - Terraform: >= $version/" "$version_tf"
        echo -e "${GREEN}✅ Updated Terraform version constraint to >= $version${NC}"
    else
        echo -e "${YELLOW}⚠️  version.tf not found${NC}"
    fi
}

# Function to show help
show_help() {
    echo "Version Management Script"
    echo "========================"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  show                    Show current version requirements"
    echo "  check                   Check latest versions online"
    echo "  update <tool> <version> Update version requirement for a tool"
    echo "  help                    Show this help message"
    echo ""
    echo "Tools:"
    echo "  terraform              Terraform version"
    echo "  aws-cli                AWS CLI version"
    echo "  ansible                Ansible version"
    echo "  python                 Python version"
    echo "  ubuntu                 Ubuntu version"
    echo ""
    echo "Examples:"
    echo "  $0 show"
    echo "  $0 check"
    echo "  $0 update terraform 1.12.2"
    echo "  $0 update aws-cli 2.15.0"
    echo ""
}

# Main script logic
case "${1:-show}" in
    "show")
        show_current_versions
        ;;
    "check")
        show_current_versions
        check_latest_versions
        ;;
    "update")
        if [[ -z "$2" || -z "$3" ]]; then
            echo -e "${RED}❌ Usage: $0 update <tool> <version>${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}🔧 Updating version requirements...${NC}"
        
        update_version "$2" "$3"
        
        # Special handling for Terraform
        if [[ "$2" == "terraform" ]]; then
            update_terraform_constraint "$3"
        fi
        
        echo ""
        echo -e "${GREEN}✅ Version update completed!${NC}"
        echo ""
        show_current_versions
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
