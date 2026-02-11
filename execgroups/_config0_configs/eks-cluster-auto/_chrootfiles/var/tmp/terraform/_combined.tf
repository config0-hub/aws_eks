# Copyright (C) 2025 Gary Leong <gary@config0.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

####FILE####:::variables.tf
# Variables
variable "aws_default_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "cloud_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "The name of the VPC where the EKS cluster will be deployed"
  type        = string
}

variable "eks_cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "eks_cluster" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-dev"
}

variable "node_pools" {
  description = "List of node pools for EKS Auto Mode compute configuration"
  type        = list(string)
  default     = ["general-purpose", "system"]
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Create own KMS key for EKS cluster encryption"
  type        = bool
  default     = false
}

# Variables for IAM user access
variable "create_iam_users" {
  description = "Whether to create IAM users and grant them access to the EKS cluster"
  type        = bool
  default     = false
}

variable "user_list" {
  description = "List of IAM user names to grant access to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "user_access_policies" {
  description = "List of EKS access policies to associate with users"
  type        = list(string)
  default     = [
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  ]
}

# Variables for IAM role access
variable "create_iam_role_access" {
  description = "Whether to grant IAM roles access to the EKS cluster"
  type        = bool
  default     = true
}

variable "role_names" {
  description = "Comma-separated list of IAM role names to grant access to the EKS cluster"
  type        = string
  default     = ""
}

variable "role_access_policies" {
  description = "List of EKS access policies to associate with roles"
  type        = list(string)
  default     = [
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy",
    "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  ]
}

####FILE####:::data.tf
# Data lookups for network information based on VPC name

# Look up the VPC ID by its name
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Look up private subnets within the VPC
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# Look up public subnets within the VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Combine both private and public subnets into lists
locals {
  all_subnet_ids     = concat(data.aws_subnets.private.ids, data.aws_subnets.public.ids)
  
  # Convert CSV role names to list and construct role ARNs only if role_names is not empty
  role_list = var.role_names != null && var.role_names != "" ? [
    for role_name in split(",", var.role_names) :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${trimspace(role_name)}"
  ] : []
}

####FILE####:::provider.tf
# AWS Provider Configuration
# Configures the AWS provider with region and default tagging strategy

# Local block to sort tags for consistent ordering
locals {
  # Convert user-provided tags map to sorted list
  sorted_cloud_tags = [
    for k in sort(keys(var.cloud_tags)) : {
      key   = k
      value = var.cloud_tags[k]
    }
  ]

  # Create a sorted and consistent map of all tags
  all_tags = merge(
    # Convert sorted list back to map
    { for item in local.sorted_cloud_tags : item.key => item.value },
    {
      # Tag indicating resources are managed by config0
      orchestrated_by = "config0"
    }
  )
}

provider "aws" {
  # Region where AWS resources will be created
  region = var.aws_default_region

  # Default tags applied to all resources with consistent ordering
  default_tags {
    tags = local.all_tags
  }

  # Optional: Configure tags to be ignored by the provider
  ignore_tags {
    # Uncomment and customize if specific tags should be ignored
    # keys = ["TemporaryTag", "AutomationTag"]
  }
}

# Terraform Version Configuration
# Specifies the required Terraform and provider versions
terraform {
  # Minimum Terraform version required
  required_version = ">= 1.1.0"

  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS provider source
      version = "~> 6.0"        # Allow 6.x versions
    }
  }
}

####FILE####:::main.tf
# Automatically tag ALL subnets for Kubernetes
resource "aws_ec2_tag" "subnet_tags" {
  count = length(local.all_subnet_ids)

  resource_id = local.all_subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${var.eks_cluster}"
  value       = "shared"
}

# Tag private subnets specifically for internal load balancers
resource "aws_ec2_tag" "private_subnet_tags" {
  count = length(data.aws_subnets.private.ids)

  resource_id = data.aws_subnets.private.ids[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

# Tag public subnets specifically for external load balancers
resource "aws_ec2_tag" "public_subnet_tags" {
  count = length(data.aws_subnets.public.ids)

  resource_id = data.aws_subnets.public.ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# Security Group for the Cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.eks_cluster}-sg"
  description = "Security group for the EKS cluster"
  vpc_id      = data.aws_vpc.selected.id

  # Inbound rules
  ingress {
    description = "Allow Kubernetes API access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow worker nodes to communicate with the control plane"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.eks_cluster}-sg"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.eks_cluster
  kubernetes_version = var.eks_cluster_version

  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids

  # *** AWS EKS Auto Mode is enabled here ***
  compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
 
  create_kms_key = var.create_kms_key

  # Only set encryption_config when creating custom KMS key
  # When create_kms_key = false, let EKS use default encryption
  encryption_config = var.create_kms_key ? {} : null

  # Use existing security group
  security_group_id = aws_security_group.eks_cluster_sg.id

  tags = var.cloud_tags
}

# IAM Role for the EKS Cluster
resource "aws_iam_role" "cluster" {
  name = "${var.eks_cluster}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_role_assume_role_policy.json
}

# Attach Policies to the Cluster Role
resource "aws_iam_role_policy_attachment" "cluster_policies" {
  count = length(local.cluster_policy_arns)

  policy_arn = local.cluster_policy_arns[count.index]
  role       = aws_iam_role.cluster.name
}

locals {
  cluster_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
  
  node_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

# IAM Policy Document for the Cluster Role
data "aws_iam_policy_document" "cluster_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "node" {
  name = "${var.eks_cluster}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach Policies to the Node Role
resource "aws_iam_role_policy_attachment" "node_policies" {
  count = length(local.node_policy_arns)

  policy_arn = local.node_policy_arns[count.index]
  role       = aws_iam_role.node.name
}

# IAM Users and EKS Access Configuration
# Only create if create_iam_users is true and user_list is not empty
resource "aws_iam_user" "eks_users" {
  for_each = var.create_iam_users ? toset(var.user_list) : toset([])
  name     = each.key

  tags = merge(
    var.cloud_tags,
    {
      Name = each.key
      Purpose = "EKS cluster access"
      Cluster = var.eks_cluster
    }
  )

  depends_on = [module.eks]
}

# Create EKS access entries for IAM users
resource "aws_eks_access_entry" "user_access" {
  for_each      = aws_iam_user.eks_users
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_user.eks_users[each.key].arn
  type          = "STANDARD"

  tags = merge(
    var.cloud_tags,
    {
      Name = "${each.key}-access-entry"
      User = each.key
      Cluster = var.eks_cluster
    }
  )

  depends_on = [module.eks]
}

# Associate access policies to users
resource "aws_eks_access_policy_association" "user_policies" {
  for_each = {
    for pair in setproduct(keys(aws_iam_user.eks_users), var.user_access_policies) :
    "${pair[0]}-${replace(split("/", pair[1])[length(split("/", pair[1])) - 1], "Amazon", "")}" => {
      user_key   = pair[0]
      policy_arn = pair[1]
    }
  }

  cluster_name  = module.eks.cluster_name
  policy_arn    = each.value.policy_arn
  principal_arn = aws_eks_access_entry.user_access[each.value.user_key].principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.user_access]
}

# IAM Roles and EKS Access Configuration
# Create EKS access entries for IAM roles - only if create_iam_role_access is true AND role_list is not empty
resource "aws_eks_access_entry" "role_access" {
  for_each = (var.create_iam_role_access && length(local.role_list) > 0) ? {
    for idx, role_arn in local.role_list : 
    replace(split("/", role_arn)[length(split("/", role_arn)) - 1], "-", "_") => role_arn
  } : {}
  
  cluster_name  = module.eks.cluster_name
  principal_arn = each.value
  type          = "STANDARD"

  tags = merge(
    var.cloud_tags,
    {
      Name = "${each.key}-access-entry"
      Role = each.key
      Cluster = var.eks_cluster
      Purpose = "EKS cluster access for IAM role"
    }
  )

  depends_on = [module.eks]
}

# Associate access policies to roles - only if role access entries exist
resource "aws_eks_access_policy_association" "role_policies" {
  for_each = {
    for pair in setproduct(keys(aws_eks_access_entry.role_access), var.role_access_policies) :
    "${pair[0]}-${replace(split("/", pair[1])[length(split("/", pair[1])) - 1], "Amazon", "")}" => {
      role_key   = pair[0]
      policy_arn = pair[1]
    }
  }

  cluster_name  = module.eks.cluster_name
  policy_arn    = each.value.policy_arn
  principal_arn = aws_eks_access_entry.role_access[each.value.role_key].principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.role_access]
}

####FILE####:::outputs.tf
# outputs.tf

output "id" {
  description = "ID (name) of the EKS cluster"
  value       = module.eks.cluster_id
}

output "arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider created by the EKS module"
  value       = module.eks.oidc_provider_arn
}

output "cluster_security_group_id" {
  description = "Security Group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs used by EKS worker nodes"
  value       = data.aws_subnets.private.ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "cluster_role_arn" {
  description = "IAM Role ARN for the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "IAM Role ARN for EKS worker nodes"
  value       = aws_iam_role.node.arn
}

# Outputs for IAM users
output "created_iam_users" {
  description = "Map of created IAM users and their ARNs"
  value = var.create_iam_users ? {
    for k, v in aws_iam_user.eks_users : k => {
      name = v.name
      arn  = v.arn
    }
  } : {}
}

output "eks_user_access_entries" {
  description = "Map of EKS access entries for users"
  value = var.create_iam_users ? {
    for k, v in aws_eks_access_entry.user_access : k => {
      cluster_name  = v.cluster_name
      principal_arn = v.principal_arn
      type         = v.type
    }
  } : {}
}

output "user_access_summary" {
  description = "Summary of users with cluster access"
  value = var.create_iam_users ? {
    cluster_name = var.eks_cluster
    users_granted_access = keys(aws_iam_user.eks_users)
    total_users = length(var.user_list)
    policies_applied = var.user_access_policies
  } : null
}

# Outputs for IAM roles
output "eks_role_access_entries" {
  description = "Map of EKS access entries for roles"
  value = (var.create_iam_role_access && length(local.role_list) > 0) ? {
    for k, v in aws_eks_access_entry.role_access : k => {
      cluster_name  = v.cluster_name
      principal_arn = v.principal_arn
      type         = v.type
    }
  } : {}
}

output "role_access_summary" {
  description = "Summary of roles with cluster access"
  value = (var.create_iam_role_access && length(local.role_list) > 0) ? {
    cluster_name = var.eks_cluster
    roles_granted_access = local.role_list
    total_roles = length(local.role_list)
    policies_applied = var.role_access_policies
  } : null
}

output "all_access_summary" {
  description = "Complete summary of all access granted to the cluster"
  value = {
    cluster_name = var.eks_cluster
    cluster_endpoint = module.eks.cluster_endpoint
    users = var.create_iam_users ? {
      enabled = true
      count = length(var.user_list)
      users = var.user_list
    } : {
      enabled = false
      count = 0
      users = []
    }
    roles = (var.create_iam_role_access && length(local.role_list) > 0) ? {
      enabled = true
      count = length(local.role_list)
      roles = local.role_list
    } : {
      enabled = false
      count = 0
      roles = []
    }
  }
}