# AWS EKS Cluster

## Description
This stack creates and configures an Amazon EKS (Elastic Kubernetes Service) cluster. It handles the creation of the EKS cluster infrastructure and optionally maps AWS IAM roles to EKS RBAC permissions.

## Variables

### Required Variables

| Name | Description | Default |
|------|-------------|---------|
| vpc_id | VPC network identifier | |
| eks_cluster_subnet_ids | Subnet IDs for EKS cluster | |
| eks_cluster_sg_id | EKS cluster security group ID | |
| eks_cluster | EKS cluster name | |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| eks_cluster_version | Kubernetes version for EKS | 1.25 |
| role_name | Configuration for role name | None |
| aws_default_region | Default AWS region | eu-west-1 |
| compute_type | Configuration for compute type | BUILD_GENERAL1_SMALL |
| image_type | Configuration for image type | LINUX_CONTAINER |
| timeout | Configuration for timeout | 2700 |

## Features
- Creates an EKS cluster with specified version and configuration
- Sets up necessary security groups and networking
- Optionally maps AWS IAM roles to EKS RBAC permissions using AWS CodeBuild
- Retrieves and outputs important cluster information, including endpoints and ARNs

## Dependencies

### Substacks
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::eks-cluster](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/eks-cluster)

### Shelloutconfigs
- [config0-publish:::aws::shellout-with-codebuild](https://api-app.config0.com/web_api/v1.0/assets/shelloutconfigs/config0-publish/aws/shellout-with-codebuild)

## License
Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.