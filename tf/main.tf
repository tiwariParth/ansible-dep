provider "aws" {
  region = "ap-south-1" 
}

resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible-key"
  public_key = file("~/.ssh/id_rsa.pub") 
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (restrict in production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_servers" {
  count         = 2 
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  key_name = aws_key_pair.ansible_key.key_name

  security_groups = [aws_security_group.allow_ssh_http.name]

  tags = {
    Name = "Ansible-Web-Server-${count.index + 1}"
  }
}

output "instance_ips" {
  value = aws_instance.web_servers[*].public_ip
}