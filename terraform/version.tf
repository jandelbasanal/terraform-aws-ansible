terraform {
  required_version = ">= 1.12.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Version requirements for this project:
# - Terraform: >= 1.12.0 (for latest features and security)
# - AWS Provider: ~> 5.0 (latest stable v5.x)
# - Ansible: >= 6.0.0 (handled by setup script)
# - Python: >= 3.8 (for Ansible compatibility)
# - Ubuntu: >= 22.04 (recommended for execution machine)
