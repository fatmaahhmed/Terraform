
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region 
}


resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block 
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "MyTerraformVPC"
  }
}
resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidr_block 
  map_public_ip_on_launch = true 
  availability_zone       = "${var.aws_region}a" 

  tags = {
    Name = "MyTerraformPublicSubnet"
  }
}
resource "aws_subnet" "my_private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.private_subnet_cidr_block 
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false 

  tags = {
    Name = "MyTerraformPrivateSubnet"
  }
}
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyTerraformIGW"
  }
}
resource "aws_eip" "nat_gateway_eip" {

  depends_on = [aws_internet_gateway.my_igw] 

  tags = {
    Name = "MyTerraformNatGatewayEIP"
  }
}


resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id      
  subnet_id     = aws_subnet.my_public_subnet.id 

  tags = {
    Name = "MyTerraformNatGateway"
  }
}


resource "aws_route_table" "my_public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"   
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "MyTerraformPublicRT"
  }
}


resource "aws_route_table" "my_private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"          
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }

  tags = {
    Name = "MyTerraformPrivateRT"
  }
}


resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.my_public_route_table.id
}


resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.my_private_subnet.id
  route_table_id = aws_route_table.my_private_route_table.id
}

resource "aws_security_group" "web_sg" {
  name        = "terraform-web-sg-http-ssh-icmp"
  description = "Allow inbound HTTP, SSH, and ICMP traffic"
  vpc_id      = aws_vpc.my_vpc.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Allow HTTP inbound"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Allow SSH inbound"
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow ICMP (Ping) from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"]  
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "WebSecurityGroup"
  }
}

 
resource "aws_instance" "my_web_server" {
  ami           = var.ami_id  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_public_subnet.id 
  vpc_security_group_ids = [aws_security_group.web_sg.id]  
  key_name      = "id_rsa" 


  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Public EC2 (Terraform)! My Public IP is $(curl -s http://checkip.amazonaws.com)</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "MyPublicWebserverEC2"
  }
}


resource "aws_instance" "my_private_ec2" {
  ami                    = var.ami_id 
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.my_private_subnet.id 
  vpc_security_group_ids = [aws_security_group.web_sg.id] 
  key_name               = "id_rsa" 


  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd # تثبيت Apache هنا كمان
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<h1>Hello from Private EC2 (Terraform)! My Private IP is $(hostname -I | awk '{print $1}')</h1>" | sudo tee /var/www/html/index.html
              echo "Checking internet access from private instance (ping google.com):" | sudo tee -a /home/ec2-user/info.txt
              ping -c 4 google.com >> /home/ec2-user/info.txt 2>&1 # اختبار الاتصال بالإنترنت
              echo "Checking internet access from private instance (curl example.com):" | sudo tee -a /home/ec2-user/info.txt
              curl -s http://example.com >> /home/ec2-user/info.txt 2>&1 # اختبار الوصول لصفحة ويب
              EOF

  tags = {
    Name = "MyPrivateApacheEC2"
  }
}
