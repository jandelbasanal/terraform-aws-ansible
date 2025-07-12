output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ubuntu.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ubuntu.id
}

output "security_group_id" {
  description = "ID of the SSH security group"
  value       = aws_security_group.ssh_access.id
}
