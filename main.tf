terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Existing VPC
data "aws_vpc" "project_vpc" {
  id = "vpc-0f7e777c109ac7bad"
}

# Public Subnet
resource "aws_subnet" "project_subnet" {
  vpc_id                  = data.aws_vpc.project_vpc.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Project-1-Public-Subnet"
  }
}

# Security Group
resource "aws_security_group" "project_sg" {
  name        = "project-1-web-security-group-bharath"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.project_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "Project-1-Web-Security-Group"
  }
}

# EC2 Web Server
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.project_subnet.id

  vpc_security_group_ids = [
    aws_security_group.project_sg.id
  ]

  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install apache2 -y

systemctl enable apache2
systemctl start apache2

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
<title>Project 1</title>
</head>
<body>
<h1>Welcome to Project 1</h1>
<h2>Linux EC2 Web Server using Terraform</h2>
<p>Apache Web Server is running successfully on AWS.</p>
</body>
</html>
HTML
EOF

  tags = {
    Name = "Project-1-Linux-Web-Server"
  }
}

output "web_server_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}
