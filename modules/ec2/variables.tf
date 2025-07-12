variable "subnet_id" {
  description = "ID of the subnet where EC2 instance will be created"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair for EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}
