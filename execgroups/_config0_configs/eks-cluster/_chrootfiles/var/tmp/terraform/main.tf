# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.eks_cluster
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_cluster_version

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id, aws_security_group.eks_nodes.id, var.eks_cluster_sg_id]
    subnet_ids              = var.eks_cluster_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  # API_AND_CONFIG_MAP lets an access grant add an EKS access entry (CON-11
  # contract, section 2b). The bootstrap flag is set to true, which is what the
  # provider reads back for a cluster made without it; it is ForceNew, so
  # leaving it unset would replace an existing cluster.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(
    var.cloud_tags,
    {
      Product = "eks"
    },
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_security_group.eks_cluster,
    aws_security_group.eks_nodes
  ]
}

