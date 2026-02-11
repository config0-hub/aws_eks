# Variables
variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "eks_cluster" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_default_region" {
  description = "AWS region where the EKS cluster is located"
  type        = string
  default     = "us-east-1"
}

# Terraform configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# AWS provider
provider "aws" {
  region = var.aws_default_region
}

# Get EKS cluster information
data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster
}

# Configure Kubernetes provider with EKS credentials
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Create namespace
resource "kubernetes_namespace" "datadog_system" {
  metadata {
    name = "datadog-system"
    labels = {
      name = "datadog-system"
    }
  }
}

# Create secret for Datadog API key (for later use)
resource "kubernetes_secret" "datadog_secret" {
  depends_on = [kubernetes_namespace.datadog_system]
  
  metadata {
    name      = "datadog-secret"
    namespace = kubernetes_namespace.datadog_system.metadata[0].name
  }

  data = {
    api-key = var.datadog_api_key
  }

  type = "Opaque"
}

# Install ONLY the Datadog Operator
resource "helm_release" "datadog_operator" {
  depends_on = [kubernetes_namespace.datadog_system]
  
  name       = "datadog-operator"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog-operator"
  version    = "1.7.0"

  namespace        = kubernetes_namespace.datadog_system.metadata[0].name
  create_namespace = false

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  disable_openapi_validation = true
  atomic          = false
  cleanup_on_fail = true

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  
  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }
}

# Outputs
output "operator_status" {
  description = "Status of the Datadog operator Helm release"
  value       = helm_release.datadog_operator.status
}

output "operator_version" {
  description = "Version of the Datadog operator"
  value       = helm_release.datadog_operator.version
}

output "datadog_namespace" {
  description = "Namespace where Datadog operator is installed"
  value       = kubernetes_namespace.datadog_system.metadata[0].name
}

output "datadog_secret_name" {
  description = "Name of the Datadog API key secret (for later use)"
  value       = kubernetes_secret.datadog_secret.metadata[0].name
}
