# Deploy Amazon Linux EC2 instance in an existing VPC public subnet

# use varibles in variables.tf for these values which
# terraform.tfvars is excluded this repo for security reasons

resource "aws_instance" "webserver" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.webserver_sg.id,
  ]

  tags = {
    Name = "Web Server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "echo '<h1>Welcome to the Webserver!</h1>' | sudo tee /var/www/html/index.html",
    ]
    
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      timeout     = "2m"
      host        = aws_eip.webserver.public_ip
    }
  }
}

resource "aws_security_group" "webserver_sg" {
  name_prefix = "Webserver_group-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = var.vpc_id
}

resource "aws_eip" "webserver" {
  vpc = true
}