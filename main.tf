
provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_security_group" "mongodb_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "mongodb" {
  ami                    = "ami-0a31f06d64a91614b" # Replace with a suitable Amazon Linux AMI ID
  instance_type          = "t2.micro"
  count                  = 3
  key_name               = "project"
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Setting up MongoDB 6.0 on Amazon Linux"
              yum update -y
              amazon-linux-extras install epel -y
              cat <<EOT >> /etc/yum.repos.d/mongodb-org-6.0.repo
              [mongodb-org-6.0]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
              EOT
              yum install -y mongodb-org
              systemctl start mongod
              systemctl enable mongod
              EOF

  tags = {
    Name = "MongoDBInstance-${count.index}"
  }
}
