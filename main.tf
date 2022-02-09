#Create VPC
resource "aws_vpc" "tf_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "demo-vpc"
  }
}
#Create Internet Gateway
resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "igw-for-vpc"
  }
}

#Create Public Subnet
/* Public subnet */
resource "aws_subnet" "tf_public_subnet" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "public-subnet"
    }
}
#Create Private Subnet
/* Private subnet */
resource "aws_subnet" "tf_private_subnet" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name        = "private-subnet"
  }
}
#Create Elastic IP
/* Elastic IP for NAT */
resource "aws_eip" "tf_nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.tf_igw]
}
#Create NAT Gateway
/* NAT */
resource "aws_nat_gateway" "tf_nat" {
  allocation_id = aws_eip.tf_nat_eip.id
  subnet_id     = aws_subnet.tf_public_subnet.id
  depends_on    = [aws_internet_gateway.tf_igw]
  tags = {
    Name        = "nat-gateway"
  }
}


#create public route table(public-route-table) and edit the route and attach IGW, associate with public subnet
resource "aws_route_table" "tf_public_route_table" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name        = "public-route-table"
  }
}
/* Edit the route and attach IGW */
resource "aws_route" "tf_public_internet_gateway" {
  route_table_id         = aws_route_table.tf_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tf_igw.id
}
/* associate with public subnet */
resource "aws_route_table_association" "tf_public_rt_association" {
  subnet_id      = aws_subnet.tf_public_subnet.id
  route_table_id = aws_route_table.tf_public_route_table.id
}


#Create a private route table and edit the route and attach NAT GW, associate with private subnet

resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name        = "privare-route-table"
  }
}
/* Edit the route and attach NAT gateway */

resource "aws_route" "tf_private_nat_gateway" {
  route_table_id         = aws_route_table.tf_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tf_nat.id
}
/* associate with private subnet */
resource "aws_route_table_association" "tf_private_rt_association" {
  subnet_id      = aws_subnet.tf_private_subnet.id
  route_table_id = aws_route_table.tf_private_route_table.id
}

#Create a security group to allow port 22,80,443
resource "aws_security_group" "tf_sg_vpc" {
  name        = "allow_SSH_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.tf_vpc.id
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
    Name = "allow_SSH_traffic"
  }
}

#Launch EC2 instances under Private and Public subnets
resource "aws_instance" "tf_ec2-public-instance" {
  ami           = "ami-0a8b4cd432b1c3063"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.tf_public_subnet.id
  vpc_security_group_ids = [aws_security_group.tf_sg_vpc.id]
  availability_zone = "us-east-1a"
  key_name = "sulbi-devops"
  #associate_public_ip_address = true
tags = {
    Name = "public-instance"
  }
}
resource "aws_instance" "tf_ec2-private-instance" {
  ami           = "ami-0a8b4cd432b1c3063"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.tf_private_subnet.id
  vpc_security_group_ids = [aws_security_group.tf_sg_vpc.id]
  availability_zone = "us-east-1a"
  key_name = "sulbi-devops"
  #associate_public_ip_address = false
tags = {
    Name = "private-instance"
  }
}

