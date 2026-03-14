variable "cidr" {
  default = "10.0.0.0/16"
}
variable "ami" {
  default = "ami-0f3caa1cf4417e51b"
}
variable "instance_type" {
  default = "m7i-flex.large"
}
variable "key" {
  default = "Modern-Musician-Portfolio-dev-nvirg"
}


variable "cluster_name" {
  default = "shashank-cluster"
}
#IAM
variable "is_eks_role_enabled" {
  type = bool
  default= true

}
variable "is_eks_nodegroup_role_enabled" {
  type = bool
  default= true

}

variable "eks_sg" {
 type    = string
  default = "eks_security_group"

}

# EKS
variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = false
}

variable "ondemand_instance_types" {
  type    = list(string)
  default = ["m7i-flex.large"]
}

variable "desired_capacity_on_demand" {
  type    = number
  default = 2
}

variable "min_capacity_on_demand" {
  type    = number
  default = 1
}

variable "max_capacity_on_demand" {
  type    = number
  default = 10
}

variable "is_eks_cluster_enabled"{
  type    = bool
  default = true
}


variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}


