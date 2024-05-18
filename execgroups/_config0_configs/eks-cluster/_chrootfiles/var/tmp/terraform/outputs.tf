output "cluster_oidc_issuer" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "security_group_ids" {
  value = aws_eks_cluster.this.vpc_config[0].security_group_ids
}

output "subnet_ids" {
  value = aws_eks_cluster.this.vpc_config[0].subnet_ids
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

#output "certificate_authority" {
#  value = aws_eks_cluster.this.certificate_authority[0].data
#}

#output "cluster_role_arn" {
#  value = aws_eks_cluster.this.role_arn
#}

#output "cluster_name" {
#  value = aws_eks_cluster.this.name
#}
#
#output "cluster_endpoint" {
#  value = aws_eks_cluster.this.endpoint
#}

#output "cluster_subnet_ids" {
#  value = aws_eks_cluster.this.vpc_config[0].subnet_ids
#}

#output "cluster_security_group_ids" {
#  value = aws_eks_cluster.this.vpc_config[0].security_group_ids
#}

