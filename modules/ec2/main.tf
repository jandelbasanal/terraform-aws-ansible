resource "aws_instance" "ubuntu" {
  ami                         = "ami-054400ced365b82a0"
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "Ubuntu24-Instance"
  }
}

