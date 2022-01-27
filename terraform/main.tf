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

  name            = "binu-rearc-quest-vpc"
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

resource "aws_security_group_rule" "ingssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
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
	
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "binu-acg-aws-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdeibCPVmpGOIgsbJfu7NBzxIEP+8FAyUQsxBe1wWafeECqRCWn1CPv7oVf6GMjVkGqN7Z9/V1CbEtjUtKN/nJ76dkunoYPJp2oM49zvzGwHh8uD3dGlZzaXNd7Ywsle0nT8RshOY1qIeVCqISnhAWmsN2cKJq70WJn45XxQlpZA/W89aMNk5L3jn2tPMd6NajD/RAUAgFpWmhfrTSk+gkUHNtk/FzWzWinTuHwP1oxk9nrP91qRwJhXCMt1pFqBjL30PeIWgCt6tNEFf9fpTpy+88Bv86bze5ggskDf6A3LhZEEanGajuvW7qYifyPXbhTLQXLgxs9v486ojqvYMH"
}
	
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "binu-rearc-quest-amzn-linux-ec2"

  ami                    = "ami-08e4e35cccc6189f4"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name   		 = "binu-acg-aws-key"

  user_data = <<-EOT
  #!/bin/bash -xe
  echo test of user_data | sudo tee /tmp/user_data.log
  curl http://169.254.169.254/latest/meta-data/local-ipv4 | sudo tee -a /tmp/user_data.log
  exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
  sudo yum update -y
  sudo yum install docker -y
  sudo systemctl enable docker.service
  sudo systemctl start docker.service
  sudo -s
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 938642921854.dkr.ecr.us-east-1.amazonaws.com
  docker pull 938642921854.dkr.ecr.us-east-1.amazonaws.com/binu-rearc-quest:latest
  EOT
	  
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name = "binu-rearc-quest-amzn-linux-ec2"
  }
}

/*	
  sudo yum install docker -y
  sudo systemctl enable docker.service
  sudo systemctl start docker.service
*/
		
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
