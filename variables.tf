# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "The CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  description = "The CIDR block for the private subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "id_rsa" {
  description = "The name of the SSH Key Pair to use for EC2 instances."
  type        = string
  default     = "id_rsa" 
}
variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances."
  type        = string
  default     = "ami-0133f9d4af72da4d0" 
 
}
