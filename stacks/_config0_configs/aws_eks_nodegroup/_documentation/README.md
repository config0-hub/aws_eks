# EKS Node Group Stack

## Description
This stack creates and manages an Amazon EKS node group attached to an existing EKS cluster. It handles the deployment of worker nodes with configurable instance types, capacity settings, and scaling parameters.

## Variables

### Required Variables

| Name | Description | Default |
|------|-------------|---------|
| eks_cluster | EKS cluster name | |
| eks_node_group_subnet_ids | Subnet IDs for EKS node group | |
| eks_node_capacity_type | EKS node capacity (ON_DEMAND/SPOT) | ON_DEMAND |
| eks_node_ami_type | AMI type for EKS nodes | AL2_x86_64 |

### Optional Variables

| Name | Description | Default |
|------|-------------|---------|
| eks_node_role_arn | IAM role ARN for EKS nodes | None |
| eks_node_instance_types | EC2 instance types for EKS nodes | ["t3.medium"] |
| eks_node_max_capacity | Maximum EKS node count | 2 |
| eks_node_min_capacity | Minimum EKS node count | 1 |
| eks_node_desired_capacity | Desired EKS node count | 1 |
| eks_node_group_name | EKS node group identifier | null |
| eks_node_disksize | Disk size for EKS nodes (GB) | 25 |
| aws_default_region | Default AWS region | eu-west-1 |
| timeout | Configuration for timeout | 2700 |

## Features
- Automatic creation of EKS node groups with customizable capacity settings
- Support for both on-demand and spot instance types
- Flexible node capacity management with min/max/desired capacity settings
- Integration with existing EKS clusters

## Dependencies

### Substacks
- [config0-publish:::output_resource_to_ui](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/output_resource_to_ui)
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::eks-nodegroup](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/eks-nodegroup)

## License
Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.