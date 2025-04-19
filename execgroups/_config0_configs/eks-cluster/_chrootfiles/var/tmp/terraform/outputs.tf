# Outputs
output "cluster_security_group_id" {
  description = "ID of the security group associated with the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  description = "ARN of IAM role used by EKS node groups"
  value       = aws_iam_role.node.arn
}

output "arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "role_arn" {
  description = "ARN of IAM role used by the EKS cluster"
  value       = aws_eks_cluster.main.role_arn
}

output "vpc_config" {
  description = "VPC configuration of the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config
}

output "eks_vpc_config" {
  description = "VPC configuration of the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config
}

output "eks_kubernetes_network_config" {
  description = "Kubernetes network configuration of the EKS cluster"
  value       = aws_eks_cluster.main.kubernetes_network_config
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_subnet_ids" {
  description = "List of subnet IDs used by the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].subnet_ids
}

output "cluster_security_group_ids" {
  description = "List of security group IDs used by the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].security_group_ids
}