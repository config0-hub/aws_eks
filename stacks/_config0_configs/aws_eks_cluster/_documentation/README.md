# AWS EKS Cluster

## Description
This stack creates and configures an Amazon EKS (Elastic Kubernetes Service) cluster. It handles the creation of the EKS cluster infrastructure and optionally maps AWS IAM roles to EKS RBAC permissions.

## Variables

### Required Variables

| Name | Description | Default |
|------|-------------|---------|
| vpc_id | VPC network identifier | &nbsp; |
| eks_cluster_subnet_ids | Subnet IDs for EKS cluster | &nbsp; |
| eks_cluster_sg_id | EKS cluster security group ID | &nbsp; |
| eks_cluster | EKS cluster name | &nbsp; |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| eks_cluster_version | Kubernetes version for EKS | 1.25 |
| role_name | Configuration for role name | None |
| aws_default_region | Default AWS region | eu-west-1 |
| compute_type | Configuration for compute type | BUILD_GENERAL1_SMALL |
| image_type | Configuration for image type | LINUX_CONTAINER |
| timeout | Configuration for timeout | 2700 |

## Dependencies

### Substacks
- [config0-publish:::tf_executor](http://config0.http.redirects.s3-website-us-east-1.amazonaws.com/assets/stacks/config0-publish/tf_executor/default)

### Execgroups
- [config0-publish:::aws_eks::eks-cluster](http://config0.http.redirects.s3-website-us-east-1.amazonaws.com/assets/exec/groups/config0-publish/aws_eks/eks-cluster/default)

### Shelloutconfigs
- [config0-publish:::aws::shellout-with-codebuild](http://config0.http.redirects.s3-website-us-east-1.amazonaws.com/assets/shelloutconfigs/config0-publish/aws/shellout-with-codebuild/default)

## License
<pre>
Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.
</pre>