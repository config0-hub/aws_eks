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
variable "aws_default_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster" {
  description = "EKS cluster name"
  type        = string
}

variable "cloud_tags" {
  description = "A map of tags to apply to all AWS resources"
  type        = map(string)
  default     = {
    owner       = "platform"
    environment = "production"
  }
}

variable "k8_tags" {
  description = "A map of labels to apply to Kubernetes resources"
  type        = map(string)
  default     = {
    owner       = "platform"
    environment = "production"
  }
}

variable "argocd_namespace" {
  description = "Namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}

####FILE####:::locals.tf
locals {
  # AWS tag handling
  sorted_cloud_tags = [
    for k in sort(keys(var.cloud_tags)) : {
      key   = k
      value = var.cloud_tags[k]
    }
  ]
  all_tags = merge(
    { for item in local.sorted_cloud_tags : item.key => item.value },
    { orchestrated_by = "config0" }
  )

  # Kubernetes tag handling
  sorted_k8_tags = {
    for k in sort(keys(var.k8_tags)) :
    k => var.k8_tags[k]
  }

  # All CRD YAMLs in the 'crds/' directory
  crd_files = fileset("${path.module}/crds", "*.yaml")
}

####FILE####:::provider.tf
provider "aws" {
  region = var.aws_default_region

  default_tags {
    tags = local.all_tags
  }

  # Optional: Configure tags to be ignored by the provider
  ignore_tags {
    # Uncomment and customize if specific tags should be ignored
    # keys = ["TemporaryTag", "AutomationTag"]
  }
}

terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
  }
}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

####FILE####:::main.tf
resource "kubernetes_manifest" "argocd_crds" {
  for_each = { for f in local.crd_files : f => yamldecode(file("${path.module}/crds/${f}")) }

  manifest = merge(
    each.value,
    {
      metadata = merge(
        try(each.value.metadata, {}),
        {
          labels = merge(
            try(each.value.metadata.labels, {}),
            local.sorted_k8_tags,
            {
              "app.kubernetes.io/managed-by" = "Helm"
            }
          ),
          annotations = merge(
            try(each.value.metadata.annotations, {}),
            {
              "meta.helm.sh/release-name"      = "argocd"
              "meta.helm.sh/release-namespace" = var.argocd_namespace
            }
          )
        }
      )
    }
  )
}

####FILE####:::outputs.tf
output "argocd_crd_files" {
  description = "List of ArgoCD CRD files applied"
  value       = local.crd_files
}

output "applied_k8s_labels" {
  description = "Kubernetes labels applied to each CRD"
  value       = local.sorted_k8_tags
}

output "aws_default_tags" {
  description = "AWS default tags applied to all resources"
  value       = local.all_tags
}
