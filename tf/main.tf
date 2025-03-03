provider "aws" {
  region = "ap-south-1" 
}

resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible-key"
  public_key = file("~/.ssh/id_rsa.pub") 
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Ansible-VPC"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"  # Subnet within the VPC
  availability_zone = "ap-south-1a" 
  tags = {
    Name = "Ansible-Subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Ansible-IGW"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Ansible-Route-Table"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.main.id 

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Ansible-Security-Group"
  }
}

resource "aws_instance" "web_servers" {
  count         = 2  
  ami           = "ami-00bb6a80f01f03502" 
  instance_type = "t2.micro"

  key_name = aws_key_pair.ansible_key.key_name

  subnet_id            = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id] 

  tags = {
    Name = "Ansible-Web-Server-${count.index + 1}"
  }
}

output "instance_ips" {
  value = aws_instance.web_servers[*].public_ip
}