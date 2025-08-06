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

####FILE####:::main.tf
terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.0" }
    helm       = { source = "hashicorp/helm", version = ">= 2.0" }
  }
  required_version = ">= 1.3"
}

provider "aws" {
  region = var.aws_default_region

  default_tags {
    tags = var.default_tags
  }
}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster
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

resource "kubernetes_namespace" "monitoring" {
  count = var.install_prometheus_grafana ? 1 : 0
  
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "metrics_server" {
  count = var.install_metrics_server ? 1 : 0
  
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  
  values = [
    <<-EOT
    args:
      - --kubelet-preferred-address-types=InternalIP
    resources:
      requests:
        cpu: 100m
        memory: 200Mi
    EOT
  ]
}

resource "helm_release" "prometheus" {
  count = var.install_prometheus_grafana ? 1 : 0
  
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  
  values = [
    <<-EOT
    server:
      retention: 15d
      persistentVolume:
        enabled: true
        size: 50Gi
    alertmanager:
      persistentVolume:
        enabled: true
        size: 10Gi
    EOT
  ]
  
  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "grafana" {
  count = var.install_prometheus_grafana ? 1 : 0
  
  name       = "grafana"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  
  values = [
    <<-EOT
    persistence:
      enabled: true
      size: 10Gi
    adminPassword: ${var.grafana_admin_password}
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-server.monitoring.svc.cluster.local
          access: proxy
          isDefault: true
    dashboards:
      default:
        kubernetes:
          gnetId: 10000
          revision: 1
          datasource: Prometheus
        node-exporter:
          gnetId: 1860
          revision: 27
          datasource: Prometheus
    service:
      type: LoadBalancer
    EOT
  ]
  
  depends_on = [
    kubernetes_namespace.monitoring,
    helm_release.prometheus
  ]
}

data "kubernetes_service" "grafana_service" {
  count = var.install_prometheus_grafana ? 1 : 0
  
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
  }
  depends_on = [helm_release.grafana]
}

output "grafana_endpoint" {
  description = "Grafana endpoint"
  value       = var.install_prometheus_grafana ? "http://${data.kubernetes_service.grafana_service[0].status[0].load_balancer[0].ingress[0].hostname}" : null
  depends_on  = [helm_release.grafana]
}

output "prometheus_endpoint" {
  description = "Prometheus server endpoint"
  value       = var.install_prometheus_grafana ? "http://${helm_release.prometheus[0].name}.monitoring.svc.cluster.local" : null
  depends_on  = [helm_release.prometheus]
}

####FILE####:::variables.tf
variable "aws_default_region" {
  type        = string
  description = "AWS region"
}

variable "eks_cluster" {
  type        = string
  description = "EKS cluster name"
}

variable "install_prometheus_grafana" {
  type        = bool
  description = "Whether to install Prometheus and Grafana"
  default     = true
}

variable "install_metrics_server" {
  type        = bool
  description = "Whether to install Metrics Server"
  default     = false
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags for AWS resources"
  default     = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  sensitive   = true
  default     = "admin"
}
