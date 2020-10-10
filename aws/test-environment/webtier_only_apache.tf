locals {
  tags_list = merge(var.default_tags, var.environment_tags)
}



#VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = merge(local.tags_list, {"Name"="main-vpc"})
}

#Internet Gateway
resource "aws_internet_gateway" "test-env-igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(local.tags_list, {"Name"="test-env-igw"})

}

#Route Table
resource "aws_route_table" "test_env_rttable" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-env-igw.id
  }

  tags = merge(local.tags_list, {"Name":"test_env_rttable"})

}

#web subnet
resource "aws_subnet" "webtier" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = merge(local.tags_list, {"Name":"webtier-subnet"})

}

#route table association for web tier
resource "aws_route_table_association" "test-route-association" {
  subnet_id      = aws_subnet.webtier.id
  route_table_id = aws_route_table.test_env_rttable.id
}

#security group

resource "aws_security_group" "allow_web_all" {
  name        = "allow_web"
  description = "Allow all web traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from internet"
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

  tags = merge(local.tags_list, {"Name":"allow_web"})

}

#network interface
resource "aws_network_interface" "webtier-nic" {
  subnet_id       = aws_subnet.webtier.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_all.id]

  tags = merge(local.tags_list, {"Name":"webtier-nic"})

}



#EC2 instance
resource "aws_instance" "web-server" {
  ami               = "ami-0817d428a6fb68645"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "us-east-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.webtier-nic.id
  }

  tags = merge(local.tags_list, {"Name":"web-server"})

  user_data = <<-EOF
		            #!/bin/bash
                sudo apt-get update
		            sudo apt-get install -y apache2
                sudo systemctl enable apache2
		            sudo systemctl start apache2		            
		            echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
	              EOF
}

#elastic ip

resource "aws_eip" "elastic_ip_web" {
  vpc                       = true
  network_interface         = aws_network_interface.webtier-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.test-env-igw, aws_instance.web-server]

  tags = merge(local.tags_list, {"Name":"eip-web-server"})

}

#Get Elastic IP address as output
output "ec2_public_ip" {
  value = aws_eip.elastic_ip_web.public_ip
}