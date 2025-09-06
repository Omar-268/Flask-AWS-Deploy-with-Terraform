terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
  access_key = ""                 # put your access key 
  secret_key = ""                 # put your secert key 
}


# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "main"  
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  
  tags = {
    Name = "main-igw"
  }
}

# Create Subnet
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id  
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "main-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "main-route-table"
  }
}

# Associate Route Table with Subnet 
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

# Create Security Group
resource "aws_security_group" "webSg" {
  name   = "webSg"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
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
    Name = "Web-sg"
  }
}

# Create Key Pair
resource "aws_key_pair" "example" {
  key_name   = "test-app-key"
  public_key = file("Path to your public key file")    # replace with the path to your local file
}

# Create EC2 Instance
resource "aws_instance" "server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
  
  connection {
    type        = "ssh"
    user        = "ubuntu"  
    private_key = file("Path to your private key file")   # replace with the path to your local file
    host        = self.public_ip
  }
  
  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "APP/app.py"                   # make sure to put the correct path 
    destination = "/home/ubuntu/app.py" 
  }
  provisioner "file" {
    source      = "APP/templates"                # make sure to put the correct path
    destination = "/home/ubuntu/templates"
  } 
  
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",
      "sudo apt-get install -y python3-pip",
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "nohup sudo python3 app.py > app.log 2>&1 &",  
    ]
  }
  
  tags = {
    Name = "web-server"
  }
}

# Output the public IP
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"  
  value       = aws_instance.server.public_dns
}
