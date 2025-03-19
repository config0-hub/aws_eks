# AWS EKS Cluster and Node Group Stack

## Description
This stack automates the creation of an EKS (Elastic Kubernetes Service) cluster on AWS along with a managed node group. It handles both the control plane setup and worker node provisioning through a streamlined workflow.

## Variables

### Required Variables
| Name | Description | Default |
|------|-------------|---------|
| eks_cluster | EKS cluster name | |
| vpc_id | VPC network identifier | |
| eks_cluster_sg_id | EKS cluster security group ID | |
| eks_node_capacity_type | EKS node capacity (ON_DEMAND/SPOT) | ON_DEMAND |
| eks_node_ami_type | AMI type for EKS nodes | AL2_x86_64 |

### Optional Variables
| Name | Description | Default |
|------|-------------|---------|
| tf_runtime | Terraform runtime version | tofu:1.6.2 |
| aws_default_region | Default AWS region | us-west-1 |
| eks_cluster_subnet_ids | Subnet IDs for EKS cluster | |
| cloud_tags_hash | Resource tags for cloud provider | null |
| remote_stateful_bucket | S3 bucket for Terraform state | null |
| role_name | Configuration for role name | null |
| eks_cluster_version | Kubernetes version for EKS | 1.25 |
| publish_to_saas | boolean to publish values to config0 SaaS UI | null |
| eks_node_instance_types | EC2 instance types for EKS nodes | ["t3.medium"] |
| eks_node_role_arn | IAM role ARN for EKS nodes | null |
| eks_node_max_capacity | Maximum EKS node count | 2 |
| eks_node_min_capacity | Minimum EKS node count | 1 |
| eks_node_desired_capacity | Desired EKS node count | 1 |
| eks_node_disksize | Disk size for EKS nodes (GB) | 25 |
| eks_node_group_name | EKS node group identifier | null |
| timeout | Timeout configuration for node group operations | 1800 |
| eks_node_group_subnet_ids | Subnet IDs for EKS node group | null |

## Features
- Creates a complete EKS cluster with control plane
- Provisions a managed node group with customizable instance types
- Supports both ON_DEMAND and SPOT capacity types
- Configurable node group scaling parameters
- AWS IAM integration for cluster authentication
- Terraform/OpenTofu based infrastructure as code implementation

## Dependencies

### Substacks
- [config0-publish:::aws_eks_cluster](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/aws_eks_cluster)
- [config0-publish:::aws_eks_nodegroup](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/aws_eks_nodegroup)

### Execgroups
- [config0-publish:::aws_eks::eks-cluster](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/eks-cluster)

### Shelloutconfigs
- [config0-publish:::aws::map-role-aws-to-eks](https://api-app.config0.com/web_api/v1.0/assets/shelloutconfigs/config0-publish/aws/map-role-aws-to-eks)

## License
Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.