output "arn" {
  description = "ARN of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}