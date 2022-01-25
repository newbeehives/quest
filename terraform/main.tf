terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

terraform {
  backend "s3" {}
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name            = "helloword-vpc"
  cidr            = "10.1.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]

  enable_nat_gateway = true
  tags = { 
	Terraform = "true"
	Environment = "dev"
  }
}

resource "aws_security_group" "sg" {
  name = "binu-rearc-quest-sg"
  description = "Rearc Quest access over HTTP/HTTPS"
  vpc_id = module.vpc.vpc_id
  tags = { 
	Terraform = "true"
	Environment = "dev"
  }
}

resource "aws_security_group_rule" "inghttp" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

 resource "aws_security_group_rule" "inghttps" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "ing3000" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}	

resource "tls_private_key" "private_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "binu-rearc-quest-ssh-key"
  public_key = tls_private_key.private_ssh_key.public_key_openssh
}
	
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "binu-rearc-quest-amzn-linux-ec2"

  ami                    = "ami-08e4e35cccc6189f4"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name   		 = "binu-rearc-quest-ssh-key"
	  
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name = "binu-rearc-quest-amzn-linux-ec2"
  }
}
	
resource "aws_alb" "alb" {
  name = "binu-rearc-quest-alb"
  internal = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.sg.id]
  tags = { 
	Terraform = "true"
	Environment = "dev"
  }
}
