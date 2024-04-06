terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }


  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "coca"
}

resource "aws_s3_bucket" "example" {
  bucket = var.backend_bucket_name
  force_destroy = true
}


resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id
  versioning_configuration {
    status = "Enabled"
  }
}


