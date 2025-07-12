variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-054400ced365b82a0"  # Ubuntu 24.04 LTS in ap-northeast-1
}