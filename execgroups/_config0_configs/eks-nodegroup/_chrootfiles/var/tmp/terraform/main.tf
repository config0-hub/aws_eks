resource "aws_eks_node_group" "main" {

  cluster_name    = var.eks_cluster
  subnet_ids      = var.eks_subnet_ids

  node_group_name = var.eks_node_group_name
  node_role_arn   = var.eks_node_role_arn

  scaling_config {
    desired_size = var.eks_node_desired_capacity
    max_size     = var.eks_node_max_capacity
    min_size     = var.eks_node_min_capacity
  }

  ami_type       = var.eks_node_ami_type
  capacity_type  = var.eks_node_capacity_type
  disk_size      = var.eks_node_disksize
  instance_types = var.eks_node_instance_types

  tags = merge(
    var.cloud_tags,
    {
      Product = "eks"
    },
  )
}
