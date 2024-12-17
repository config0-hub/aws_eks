module "eks" {
  #source                          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v18.31.2"
  source                          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v17.23.0"
  cluster_version                 = var.eks_cluster_version
  cluster_name                    = var.eks_cluster
  vpc_id                          = var.vpc_id
  subnets                         = var.subnet_ids

  #cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  node_groups = {
    eks_nodes = {
      instance_type    = var.eks_node_instance_type
      desired_capacity = tonumber(var.eks_node_desired_capacity)
      max_capacity     = tonumber(var.eks_node_max_capacity)
      min_capacity     = tonumber(var.eks_node_min_capacity)
    }
  }

  manage_aws_auth = false

  tags = merge(
    var.cloud_tags,
    {
      Product = "eks"
    },
  )

}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}


