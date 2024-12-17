variable "aws_default_region" {
  default = "us-west-1"
}

variable "eks_node_instance_type" {
  default = "t3.small"
}

variable "eks_cluster_version" {
  default = "1.24"
}

variable "vpc_id" {
  default = "vpc-08c62f67d9efab21d"
}

variable "subnet_ids" {
}

variable "eks_cluster" {
  default = "dev-k8"
}

variable "eks_node_min_capacity" {
  default = "1"
}

variable "eks_node_max_capacity" {
  default = "1"
}

variable "eks_node_desired_capacity" {
  default = "1"
}

variable "cluster_endpoint_private_access" {
  default = true
}

variable "cluster_endpoint_public_access" {
  default = true
}

variable "cloud_tags" {
  description = "additional tags as a map"
  type        = map(string)
  default     = {}
}
