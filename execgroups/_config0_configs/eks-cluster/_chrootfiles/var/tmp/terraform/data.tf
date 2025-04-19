# Kubernetes Provider Configuration
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.main.id
}
