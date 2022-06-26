terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.20.1"
    }
  }
}
provider "aws" {
  # Configuration options
   region = "ap-south-1"
}
resource "aws_vpc" "ownvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ownvpc"
  }
}
resource "aws_subnet" "ownsubnet" {
  vpc_id     = aws_vpc.ownvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "ownsubnet"
  }
}
resource "aws_internet_gateway" "ownigw" {
  vpc_id = aws_vpc.ownvpc.id

  tags = {
    Name = "ownigw"
  }
}
resource "aws_route_table" "ownrt" {
  vpc_id = aws_vpc.ownvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ownigw.id
  }
   tags = {
    Name = "own-rt"
  }
}
resource "aws_route_table_association" "ownrta" {
  subnet_id      = aws_subnet.ownsubnet.id
  route_table_id = aws_route_table.ownrt.id
}
resource "aws_security_group" "ownsg" {
  name        = "ownsecuritygroup"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.ownvpc.id

  ingress {
    description      = "http"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "own-sg"
  }
}

data "aws_ami" "my-ami"{
  most_recent = true
   filter{
     name="name"
     values=["amzn2-ami-kernel-*-x86_64-gp2"]
   }
    filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
 
  owners = ["amazon"]
}
resource "aws_instance" "web" {
  ami           = data.aws_ami.my-ami.id
  instance_type = "t2.micro"
   associate_public_ip_address =true
   subnet_id=aws_subnet.ownsubnet.id
  vpc_security_group_ids = [aws_security_group.ownsg.id]
   key_name="awskey"
  tags = {
    Name = "my-instance"
  }
  user_data = <<-EOF
#!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx
EOF
}
output "ip"{
  value = aws_instance.web.public_ip
  }
output "ami"{
  value = aws_instance.web.ami
}
 
