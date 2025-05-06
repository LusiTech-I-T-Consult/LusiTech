resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data

  tags = {
    Name = "App-Server"
  }
}

output "instance_id" {
  value = aws_instance.app_server.id
}
