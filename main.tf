#Implementation IAC

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "VPCPROD" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC Producao"
  }
}

#Create public subnet
resource "aws_subnet" "SUBNETAPP" {
  vpc_id     = aws_vpc.VPCPROD.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public Subnet"
  }
}


#Create privante subnet
resource "aws_subnet" "SUBNETDB" {
  vpc_id = aws_vpc.VPCPROD.id
  cidr_block = "10.0.2.0/24"
  tags = {
    "Name" = "Private Subnet"
  }
}

#Create internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.VPCPROD.id

  tags = {
    Name = "IGW"
  }
}


# routing table for VPC
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.VPCPROD.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "ROUTE TABLE"
  }
}

# Link betweeen RT and Subnet
resource "aws_route_table_association" "PUBLIC_ROUTE" {
  subnet_id      = aws_subnet.SUBNETAPP.id
  route_table_id = aws_route_table.RT.id
}

#Create firewall VPC

resource "aws_security_group" "main" {
  name        = "main"
  description = "Allow SSH to use ec2 instance"
  vpc_id      = aws_vpc.VPCPROD.id

  ingress {
    description = "Allow port on security group"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["MY IP ADDRESS/32" , "ANOTHER IP ADDRESS/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main"
  }
}


resource "aws_instance" "linux" {
  
  ami           = "ami-0747bdcabd34c712a" # us-east-1
  instance_type = "t2.micro"
  disable_api_termination= false
  subnet_id = aws_subnet.SUBNETAPP.id
  key_name              =   "NAMEKEYPAIR"
  vpc_security_group_ids  = [aws_security_group.main.id]
  
}

output "public_ip" {
    value = "${aws_instance.linux.*.public_ip}"
}


