terraform {
  backend "s3" {
    bucket = "tyio-terraform"
    key    = "deploying-webapp.tfstate"
    region = "ap-southeast-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.24"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  default = true
}

resource aws_security_group "launch-wizard" {
  name = "launch-wizard-1"
  description = "launch-wizard-1 created 2023-11-23T07:09:37.619Z"
}

resource "aws_security_group_rule" "launch-wizard-egress" {
  type                     = "egress"
  security_group_id        = aws_security_group.launch-wizard.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "launch-wizard-ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.launch-wizard.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_db_instance" "webapp_postgres" {
  apply_immediately = true
  identifier        = "django-webapp"

  instance_class              = "db.t3.micro"
  copy_tags_to_snapshot       = true
  skip_final_snapshot         = true
  allocated_storage           = 20
  max_allocated_storage       = 1000
  engine                      = "postgres"
  username                    = "postgres"
  manage_master_user_password = true
}

resource "aws_instance" "db-jumphost" {
  ami                    = "ami-02453f5468b897e31"
  instance_type          = "t2.micro"
  key_name               = "db-jumphost-keypair"
  security_groups = [aws_security_group.ec2-rds.name, aws_security_group.launch-wizard.name]
  vpc_security_group_ids = [aws_security_group.ec2-rds.id, aws_security_group.launch-wizard.id]
}

resource "aws_key_pair" "jumphost-keypair" {
  key_name   = "db-jumphost-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDGVJbqhFHx/WaqGRjkzPijiI9FrAWy6VFP75SiW7NxNPkYsb4yVyyhG9nGl9luZnsEXqtWn3UH0uV6d9R14gcHBDqvcGys8HqG8kXX+ADWQGk+kipixSMxK3tPSmyOJ31uW7WfuJkC5tRfvUencjTMPAnDkay7cNhbXiVb/dNBclLs16uq9sCjXiTx5syze6F9lUbppYye8CDWTnyNeB3DBhfRbja6KzzoBRqesvaiCZ6yCO8SgrkEeScvuD+MEwO3x08hI7UP+pcXCqPtabMahOlVsXZTJ/a+5tNjQQUodYahTz+wdWxdryOpKXrP6VFfr+JKe2zZO+4gA4IibL/"
}

resource "aws_security_group" "ec2-rds" {
  name        = "ec2-rds-1"
  description = "Security group attached to instances to securely connect to django-webapp. Modification could lead to connection loss."
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "ec2_egress_sgr" {
  type              = "egress"
  description       = "Rule to allow connections to django-webapp from any instances this security group is attached to"
  security_group_id = aws_security_group.ec2-rds.id
  from_port         = aws_db_instance.webapp_postgres.port
  to_port           = aws_db_instance.webapp_postgres.port
  protocol          = "tcp"
  prefix_list_ids   = []
}

resource "aws_security_group" "rds-ec2" {
  name        = "rds-ec2-1"
  description = "Security group attached to django-webapp to allow EC2 instances with specific security groups attached to connect to the database. Modification could lead to connection loss."
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "rds_ingress_sgr" {
  type                     = "ingress"
  description              = "Rule to allow connections from EC2 instances with sg-0b4182d0f278753c0 attached"
  security_group_id        = aws_security_group.rds-ec2.id
  from_port                = aws_db_instance.webapp_postgres.port
  to_port                  = aws_db_instance.webapp_postgres.port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2-rds.id
}