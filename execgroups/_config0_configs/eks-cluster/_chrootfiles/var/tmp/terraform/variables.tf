# Variables
variable "aws_default_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-1"
}

variable "eks_cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.24"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be deployed"
  type        = string
}

variable "eks_cluster_subnet_ids" {
  description = "List of subnet IDs where the EKS cluster will be deployed"
  type        = list(string)
}

variable "eks_cluster" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_cluster_sg_id" {
  description = "ID of the additional security group to attach to the EKS cluster"
  type        = string
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks which can access the EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cloud_tags" {
  description = "Additional tags as a map to apply to all resources"
  type        = map(string)
  default     = {}
}

