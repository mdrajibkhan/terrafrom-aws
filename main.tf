terraform {
    backend "remote" {
    organization = "demo-org-for-practice"
    workspaces {
      name = "my-workspace"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# 1. create vpc
resource "aws_vpc" "vpc-1" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "vpc-1"
  }
}

# 2. create internet gateway
resource "aws_internet_gateway" "gateway-1" {
  vpc_id = aws_vpc.vpc-1.id

  tags = {
    Name = "gateway-1"
  }
}

# 3. create custom route table
resource "aws_route_table" "route-table-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gateway-1.id
    }
  
  route {
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.gateway-1.id
    }
    

  tags = {
    Name = "route-table-1"
  }
}

# 4. create a subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.vpc-1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "subnet-1"
  }
}

# 5. associate subnet with route table
resource "aws_route_table_association" "routing-table-association-1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route-table-1.id
}

# 6. create security group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.vpc-1.id

  ingress {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "allow_web"
  }
}

# 7. create newtwork interface
resource "aws_network_interface" "web-server-1-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  # attachment {
  #   instance     = aws_instance.instance-1.id
  #   device_index = 1
  # }
}

# 8. create and assign elastic ip in the network interface
resource "aws_eip" "elastic-ip-1" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-1-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gateway-1, aws_instance.instance-1]
}

# 9. create ubuntu server and install/enable apache2
resource "aws_instance" "instance-1" {
  ami = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "musta-key"
  tags = {
      Name = "instance-1"
  }
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-1-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo welcome to server from ec2 created by terraform > /var/www/html/index.html'
              EOF
}
