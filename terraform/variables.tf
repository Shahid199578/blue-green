# General variables
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "demoapp-cluster"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t2.medium"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  default     = "ami-0e35ddab05955cf57" # Replace with a valid AMI ID
}

variable "instance_type_ext" {
  description = "Instance type for EC2 instances"
  default     = "t2.medium"
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  default     = "terraform-key" # Replace with your key pair name
}

variable "allowed_ssh_cidr" {
  description = "Allowd CIDR range to connect EC2"
  default     = "0.0.0.0/0"
}