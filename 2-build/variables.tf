variable "backend_bucket_name" {
  description = "Value of the AMI for the EC2 instance"
  type        = string
  default     = "coca-terraform-state-files"
}
variable "state_file_name" {
  description = "Value of the AMI for the EC2 instance"
  type        = string
  default     = "terraform.tfstate"
}
