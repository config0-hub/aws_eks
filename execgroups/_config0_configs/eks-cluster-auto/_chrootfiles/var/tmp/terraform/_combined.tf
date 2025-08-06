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

variable "eks_cluster" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-dev"
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

# Combine both private and public subnets into lists
locals {
  all_subnet_ids     = concat(data.aws_subnets.private.ids, data.aws_subnets.public.ids)
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

# EKS Cluster using terraform-aws-modules
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster
  cluster_version = "1.33"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids

  # *** AWS EKS Auto Mode is enabled here ***
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system" ]
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Use existing security group
  cluster_security_group_id = aws_security_group.eks_cluster_sg.id

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
    }
  }
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
