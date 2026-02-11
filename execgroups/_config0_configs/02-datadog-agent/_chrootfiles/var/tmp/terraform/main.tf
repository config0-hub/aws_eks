##############################
# VARIABLES
##############################
variable "eks_cluster" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_default_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_apm" {
  description = "Enable APM monitoring with instrumentation"
  type        = bool
  default     = false
}

variable "enable_log" {
  description = "Enable log collection"
  type        = bool
  default     = false
}

variable "datadog_secret_name" {
  description = "Name of the Kubernetes secret containing Datadog API key"
  type        = string
  default     = "datadog-secret"
}

variable "datadog_secret_key" {
  description = "Key name within the secret that contains the Datadog API key"
  type        = string
  default     = "api-key"
}

variable "datadog_namespace" {
  description = "Kubernetes namespace for Datadog operator"
  type        = string
  default     = "datadog-system"
}

variable "datadog_tags" {
  description = "List of tags to apply to Datadog agent"
  type        = list(string)
  default     = [
    "env:dev",
    "managedby:terraform",
    "purpose:poc"
  ]
}

##############################
# PROVIDERS
##############################
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "aws" {
  region = var.aws_default_region
}

data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster
}

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

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

##############################
# DATADOGAGENT CUSTOM RESOURCE
##############################
resource "kubectl_manifest" "datadogagent" {
  yaml_body = yamlencode({
    apiVersion = "datadoghq.com/v2alpha1"
    kind       = "DatadogAgent"
    metadata = {
      name      = "datadog"
      namespace = var.datadog_namespace
    }
    spec = merge(
      {
        global = {
          site = "datadoghq.com"
          credentials = {
            apiSecret = {
              secretName = var.datadog_secret_name
              keyName    = var.datadog_secret_key
            }
          }
          clusterName = var.eks_cluster
          registry    = "public.ecr.aws/datadog"
          tags        = var.datadog_tags
        }
      },
      var.enable_apm || var.enable_log ? {
        features = merge(
          var.enable_apm ? {
            apm = {
              instrumentation = {
                enabled = true
                targets = [{
                  name = "default-target"
                  ddTraceVersions = {
                    java   = "1"
                    python = "3"
                    js     = "5"
                    php    = "1"
                    dotnet = "3"
                  }
                }]
              }
            }
          } : {},
          var.enable_log ? {
            logCollection = {
              enabled             = true
              containerCollectAll = true
            }
          } : {}
        )
      } : {}
    )
  })
}
