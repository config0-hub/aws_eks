# AWS EKS Cluster Terraform Module

This module provisions an AWS Elastic Kubernetes Service (EKS) cluster with associated IAM roles, security groups, and networking components.

## Features

- Creates an EKS cluster with configurable version and access settings
- Sets up required IAM roles for cluster and node groups with appropriate policies
- Configures security groups for cluster and node communication
- Supports both private and public endpoint access
- Provides comprehensive outputs for cluster information

## Requirements

- OpenTofu >= 1.8.8
- AWS provider
- Kubernetes provider

## Usage

```hcl
module "eks_cluster" {
  source = "./path/to/module"

  eks_cluster              = "my-eks-cluster"
  eks_cluster_version      = "1.28"
  vpc_id                   = "vpc-0123456789abcdef0"
  eks_cluster_subnet_ids   = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  eks_cluster_sg_id        = "sg-0123456789abcdef0"
  
  # Optional parameters
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  public_access_cidrs             = ["10.0.0.0/8"]
  
  cloud_tags = {
    Environment = "Production"
    Project     = "MyApp"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_default_region | AWS region where resources will be created | string | `"us-west-1"` | No |
| eks_cluster_version | Kubernetes version to use for the EKS cluster | string | `"1.24"` | No |
| vpc_id | ID of the VPC where the EKS cluster will be deployed | string | n/a | Yes |
| eks_cluster_subnet_ids | List of subnet IDs where the EKS cluster will be deployed | list(string) | n/a | Yes |
| eks_cluster | Name of the EKS cluster | string | n/a | Yes |
| eks_cluster_sg_id | ID of the additional security group to attach to the EKS cluster | string | n/a | Yes |
| cluster_endpoint_private_access | Indicates whether or not the EKS private API server endpoint is enabled | bool | `true` | No |
| cluster_endpoint_public_access | Indicates whether or not the EKS public API server endpoint is enabled | bool | `true` | No |
| public_access_cidrs | List of CIDR blocks which can access the EKS public API server endpoint | list(string) | `["0.0.0.0/0"]` | No |
| cloud_tags | Additional tags as a map to apply to all resources | map(string) | `{}` | No |

## Outputs

| Name | Description |
|------|-------------|
| cluster_security_group_id | ID of the security group associated with the EKS cluster |
| node_role_arn | ARN of IAM role used by EKS node groups |
| arn | ARN of the EKS cluster |
| platform_version | Platform version of the EKS cluster |
| version | Kubernetes version of the EKS cluster |
| role_arn | ARN of IAM role used by the EKS cluster |
| vpc_config | VPC configuration of the EKS cluster |
| eks_vpc_config | VPC configuration of the EKS cluster |
| eks_kubernetes_network_config | Kubernetes network configuration of the EKS cluster |
| cluster_name | Name of the EKS cluster |
| endpoint | Endpoint for the EKS cluster API server |
| cluster_subnet_ids | List of subnet IDs used by the EKS cluster |
| cluster_security_group_ids | List of security group IDs used by the EKS cluster |

## Notes

- The module configures both the EKS cluster and worker node IAM roles with necessary permissions
- Security groups are configured to allow proper communication between the cluster and worker nodes
- The Kubernetes provider is configured to use the EKS cluster credentials

## License

Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.