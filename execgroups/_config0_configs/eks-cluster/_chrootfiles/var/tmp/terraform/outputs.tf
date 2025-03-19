output "cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "arn" {
  value = aws_eks_cluster.main.arn
}

output "platform_version" {
  value = aws_eks_cluster.main.platform_version
}

output "version" {
  value = aws_eks_cluster.main.version
}

output "role_arn" {
  value = aws_eks_cluster.main.role_arn
}

output "vpc_config" {
  value = aws_eks_cluster.main.vpc_config
}

output "eks_vpc_config" {
  value = aws_eks_cluster.main.vpc_config
}

output "eks_kubernetes_network_config" {
  value = aws_eks_cluster.main.kubernetes_network_config
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_subnet_ids" {
  value = aws_eks_cluster.main.vpc_config[0].subnet_ids
}

output "cluster_security_group_ids" {
  value = aws_eks_cluster.main.vpc_config[0].security_group_ids
}
