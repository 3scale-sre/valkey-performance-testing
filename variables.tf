variable "ec2_instance_type" {
  type    = string
  default = "m7g.xlarge"
}

variable "ec2_ssh_key_name" {
  type        = string
  description = "AWS EC2 SSH key-pair name to be deployed on EC2 instance for `ec2-user`"
}

variable "ec_instance_type" {
  type    = string
  default = "cache.m7g.xlarge"
}

variable "ec_preferred_az" {
  type    = list(string)
  default = ["us-east-1a"]
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_private_subnet_id" {
  type        = list(string)
  description = "VPC private subnets ID list, minimum 2, first one must match with AZ on var.ec_preferred_az to guarantee EC2 and EC runs on same AZ (e.g. `subnet-xxx-a`,`subnet-xxx-b`)"
}
