variable "region" {
  default = "eu-west-1"
}

# variable "profile" {
#   default = "default"
# }

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR Block for the VPC"
  type        = string
}

variable "ami_id" {
  default     = "ami-066734adba283ab4b"
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Instance type for the EC2 instance"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of eks cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "eks_cluster_version" {
  type        = string
  description = "Version of the EKS to be deployed"
  default     = "1.27"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}
