variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
  
}

variable "subnet_cidrs" {
    description = "List of CIDR blocks for the subnets."
    type        = list(string)
    default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-north-1a", "eu-north-1b"]
}
