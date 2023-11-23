terraform {
  backend "s3" {
    bucket = "tyio-terraform"
    key    = "deploying-webapp-app_runner.tfstate"
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

resource "aws_apprunner_connection" "apprunner_github_connection" {
  connection_name = "apprunner-github"
  provider_type   = "GITHUB"
}

resource "aws_apprunner_service" "django_apprunner" {
  service_name = "django-apprunner"

  source_configuration {
    authentication_configuration {
      connection_arn = aws_apprunner_connection.apprunner_github_connection.arn
    }
    code_repository {
      code_configuration {
        configuration_source = "REPOSITORY"
      }
      repository_url = "https://github.com/tyng94/aws-deploy-webapp"
      source_code_version {
        type  = "BRANCH"
        value = "main"
      }
    }
  }

  observability_configuration {
    observability_enabled = false
  }

  tags = {
    Name = "example-apprunner-service"
  }
}