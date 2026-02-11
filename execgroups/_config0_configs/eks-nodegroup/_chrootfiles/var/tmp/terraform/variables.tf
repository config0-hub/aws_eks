variable "aws_default_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-west-1"
}

variable "eks_cluster" {
  description = "Name of the EKS cluster where the node group will be created"
  type        = string
}

variable "eks_node_group_subnet_ids" {
  description = "List of subnet IDs where the EKS node group instances will be launched"
  type        = list(string)
}

variable "eks_node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN of the IAM role that provides permissions for the EKS node group"
  type        = string
}

variable "eks_node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.eks_node_capacity_type)
    error_message = "Valid values for eks_node_capacity_type are ON_DEMAND or SPOT."
  }
}

variable "eks_node_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Valid values: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, BOTTLEROCKET_x86_64"
  type        = string
  default     = "AL2_x86_64"

  validation {
    condition     = contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64"], var.eks_node_ami_type)
    error_message = "Valid values for eks_node_ami_type are AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM, BOTTLEROCKET_ARM_64, or BOTTLEROCKET_x86_64."
  }
}

variable "eks_node_max_capacity" {
  description = "Maximum number of worker nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_min_capacity" {
  description = "Minimum number of worker nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_desired_capacity" {
  description = "Desired number of worker nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_disksize" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 30
}

variable "eks_node_instance_types" {
  description = "List of instance types associated with the EKS Node Group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "cloud_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

