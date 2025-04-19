# AWS EKS Node Group Terraform Module

This module provisions an AWS EKS node group with customizable configuration options. It allows you to set up worker nodes for your Amazon EKS cluster efficiently, with sensible defaults and flexible scaling options.

## Features

- Creates an EKS node group for an existing EKS cluster
- Configurable node capacity type (ON_DEMAND or SPOT)
- Supports multiple instance types for cost optimization
- Custom AMI type selection (AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, etc.)
- Configurable disk size and scaling parameters

## Usage

```hcl
module "eks_node_group" {
  source = "path/to/module"

  eks_cluster              = "my-eks-cluster"
  eks_node_group_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
  eks_node_group_name      = "my-node-group"
  eks_node_role_arn        = "arn:aws:iam::123456789012:role/eks-node-role"
  
  # Optional configurations with defaults
  eks_node_capacity_type    = "ON_DEMAND"  # or "SPOT"
  eks_node_ami_type         = "AL2_x86_64" # Amazon Linux 2 AMI type
  eks_node_max_capacity     = 3
  eks_node_min_capacity     = 1
  eks_node_desired_capacity = 2
  eks_node_disksize         = 50
  eks_node_instance_types   = ["t3.medium", "t3.large"]
  
  cloud_tags = {
    Environment = "production"
    Owner       = "infrastructure-team"
  }
}
```

## Requirements

- OpenTofu >= 1.8.8
- AWS Provider

## Input Variables

| Variable Name | Description | Type | Default | Required |
|---------------|-------------|------|---------|----------|
| `aws_default_region` | The AWS region to deploy resources into | string | `"us-west-1"` | no |
| `eks_cluster` | Name of the EKS cluster where the node group will be created | string | | yes |
| `eks_node_group_subnet_ids` | List of subnet IDs where the EKS node group instances will be launched | list(string) | | yes |
| `eks_node_group_name` | Name of the EKS node group | string | | yes |
| `eks_node_role_arn` | ARN of the IAM role that provides permissions for the EKS node group | string | | yes |
| `eks_node_capacity_type` | Type of capacity associated with the EKS Node Group (ON_DEMAND, SPOT) | string | `"ON_DEMAND"` | no |
| `eks_node_ami_type` | Type of Amazon Machine Image (AMI) associated with the EKS Node Group | string | `"AL2_x86_64"` | no |
| `eks_node_max_capacity` | Maximum number of worker nodes in the EKS node group | number | `1` | no |
| `eks_node_min_capacity` | Minimum number of worker nodes in the EKS node group | number | `1` | no |
| `eks_node_desired_capacity` | Desired number of worker nodes in the EKS node group | number | `1` | no |
| `eks_node_disksize` | Disk size in GiB for worker nodes | number | `30` | no |
| `eks_node_instance_types` | List of instance types associated with the EKS Node Group | list(string) | `["t3.medium", "t3.large"]` | no |
| `cloud_tags` | Additional tags to apply to all resources | map(string) | `{}` | no |

## Outputs

| Output Name | Description |
|-------------|-------------|
| `arn` | ARN of the EKS Node Group |

## License

Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.