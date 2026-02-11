# Define required variables
variable "eks_cluster" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "user_list" {
  description = "List of IAM user names to grant access to the EKS cluster"
  type        = list(string)
}

# AWS provider configuration
provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

# Lookup EKS cluster dynamically using the provided name
data "aws_eks_cluster" "eks" {
  name = var.eks_cluster
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = var.eks_cluster
}

# Iterate over the list of users and create resources
resource "aws_iam_user" "users" {
  for_each = toset(var.user_list)
  name     = each.key
}

resource "aws_eks_access_entry" "users" {
  for_each      = aws_iam_user.users
  cluster_name  = data.aws_eks_cluster.eks.name
  principal_arn = aws_iam_user.users[each.key].arn
  type          = "STANDARD"
}

# Associate the AmazonEKSAdminPolicy to each user
resource "aws_eks_access_policy_association" "admin_policy" {
  for_each      = aws_iam_user.users
  cluster_name  = data.aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.users[each.key].principal_arn

  access_scope {
    type = "cluster"
  }
}

# Associate the AmazonEKSClusterAdminPolicy to each user
resource "aws_eks_access_policy_association" "cluster_admin_policy" {
  for_each      = aws_iam_user.users
  cluster_name  = data.aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.users[each.key].principal_arn

  access_scope {
    type = "cluster"
  }
}