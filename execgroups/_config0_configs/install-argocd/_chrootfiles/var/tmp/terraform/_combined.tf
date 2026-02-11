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
  description = "Namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "7.1.3"
}

variable "argocd_chart_repo_url" {
  description = "Helm repo URL for ArgoCD"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}


####FILE####:::provider.tf

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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
  }
}

provider "aws" {
  region = var.aws_default_region

  default_tags {
    tags = local.all_tags
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

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}


####FILE####:::main.tf

locals {
  # AWS tag handling (for completeness, same as your CRD file)
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

  # Kubernetes tag handling (sorted for consistency)
  sorted_k8_tags = {
    for k in sort(keys(var.k8_tags)) :
    k => var.k8_tags[k]
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name   = var.argocd_namespace
    labels = local.sorted_k8_tags
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = var.argocd_chart_repo_url
  version          = var.argocd_chart_version
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  set = [
    {
      name  = "installCRDs"
      value = "false"
    }
  ]

  values = [yamlencode({
    controller = { replicaCount = 2 }
    repoServer = { replicaCount = 2 }
    server     = { replicaCount = 2 }
    applicationSet = { replicaCount = 2 }
    dex        = { replicaCount = 2 }
    redis      = { replicaCount = 2 }
    global = {
      labels = local.sorted_k8_tags
    }
  })]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

output "argocd_release_name" {
  description = "ArgoCD Helm release name"
  value       = helm_release.argocd.name
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.argocd_namespace
}

output "k8_tags" {
  description = "Ordered tags applied to ArgoCD resources"
  value       = local.sorted_k8_tags
}
