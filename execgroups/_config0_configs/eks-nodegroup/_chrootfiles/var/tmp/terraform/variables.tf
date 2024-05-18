variable "aws_default_region" {
  default = "us-west-1"
}

variable "eks_cluster" {}
variable "eks_subnet_ids" {}
variable "eks_node_group_name" {}
variable "eks_node_role_arn" {}

# ON_DEMAND, SPOT
# AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM

variable "eks_node_capacity_type" { default = "ON_DEMAND" }
variable "eks_node_ami_type" { default = "AL2_x86_64" }
variable "eks_node_max_capacity" { default = 1 }
variable "eks_node_min_capacity" { default = 1 }
variable "eks_node_desired_capacity" { default = 1 }
variable "eks_node_disksize" { default = 30 }
variable "eks_node_instance_types" { default = ["t3.medium", "t3.large"] }

variable "cloud_tags" {
  description = "additional tags as a map"
  type        = map(string)
  default     = {}
}
