# AWS EKS Cluster

This stack creates an AWS EKS cluster using Terraform.

## Dependencies

### Substacks
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::eks-cluster-auto](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/eks-cluster-auto)

## Infrastructure

- AWS EKS Cluster
- Associated IAM roles and policies
- Security groups

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | The name of the VPC | string | - | yes |
| eks_cluster | The name of the EKS cluster | string | - | yes |
| aws_default_region | The AWS region | string | eu-west-1 | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | The endpoint for the EKS cluster API server |
| arn | The ARN of the EKS cluster |
| cluster_security_group_id | The security group ID attached to the EKS cluster |
| cluster_role_arn | The ARN of the IAM role used by the EKS cluster |
| oidc_provider_arn | The ARN of the OIDC provider |
| node_role_arn | The ARN of the IAM role used by the EKS nodes |
