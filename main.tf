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
resource "aws_instance" "web" {
  count=3
  ami           = "ami-08df646e18b182346"
  instance_type = "t2.micro"

  tags = {
    Name = "tf-${count.index}"
  }
}