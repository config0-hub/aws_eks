variable "aws_default_region" {
  default = "us-west-1"
}

variable "eks_cluster_version" {
  default = "1.24"
}

variable "vpc_id" {}
variable "subnet_ids" {}
variable "eks_cluster" {}
variable "sg_id" {}

variable "cluster_endpoint_private_access" {
  default = true
}

variable "cluster_endpoint_public_access" {
  default = true
}

variable "public_access_cidrs" {
    default   = ["0.0.0.0/0"]
}

variable "cloud_tags" {
  description = "additional tags as a map"
  type        = map(string)
  default     = {}
}
