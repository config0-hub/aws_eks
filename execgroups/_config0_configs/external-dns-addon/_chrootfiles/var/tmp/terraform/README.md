# ExternalDNS EKS Add-on Terraform Module

This Terraform module deploys ExternalDNS as an EKS add-on with a dual IAM role architecture for enhanced security and flexibility.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS Account                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌──────────────────────────── ─┐    ┌─────────────────────────────────────────┐ │
│  │     General IAM Role         │    │         EKS Cluster                     │ │
│  │   external-dns-yofool        │    │                                         │ │
│  │                              │    │  ┌─────────────────────────────────── ─┐│ │
│  │  ┌─────────────────────────┐ │    │  │         Kubernetes                  ││ │
│  │  │     DNS Permissions     │ │    │  │                                     ││ │
│  │  │                         │ │    │  │  ┌────────────────────────────────┐ ││ │
│  │  │  • route53:ListHosted   │ │    │  │  │       external-dns namespace   │ ││ │
│  │  │    Zones                │ │    │  │  │                                │ ││ │
│  │  │  • route53:ChangeBatch  │ │    │  │  │  ┌─────────────────────────────┐ ││ │ │
│  │  │  • route53:GetChange    │ │    │  │  │  │    ServiceAccount           │ ││ │ │
│  │  │  • route53:List         │ │    │  │  │  │    external-dns             │ ││ │ │
│  │  │    ResourceRecord...    │ │    │  │  │  │                             │ ││ │ │
│  │  └─────────────────────────┘ │    │  │  │  │  Annotations:               │ ││ │ │
│  │                              │    │  │  │  │  eks.amazonaws.com/role-arn │ ││ │ │
│  │  External ID: external-dns   │◄───┼──┼──┼──┼──► │                        │ ││ │ │
│  └──────────────────────────── ─┘    │  │  │  └─────────────────────────────┘ ││ │ │
│               ▲                      │  │  │                                  ││ │ │
│               │                      │  │  │  ┌─────────────────────────────┐ ││ │ │
│               │ sts:AssumeRole       │  │  │  │    ExternalDNS Pod          │ ││ │ │
│               │                      │  │  │  │                             │ ││ │ │
│               │                      │  │  │  │  Environment Variables:     │ ││ │ │
│               │                      │  │  │  │  • AWS_ROLE_ARN             │ ││ │ │
│               │                      │  │  │  │  • AWS_STS_EXTERNAL_ID      │ ││ │ │
│               │                      │  │  │  │  • AWS_DEFAULT_REGION       │ ││ │ │
│  ┌─────────────────────────────┐     │  │  │  └─────────────────────────────┘ ││ │ │
│  │   Cluster-Specific Role     │     │  │  └───────────────────────────────── ┘│ │ │
│  │ eks-dev-external-dns-role   │     │  └─────────────────────────────────────┘│ │
│  │                             │     │                                         │ │
│  │  ┌─────────────────────────┐ │     │  ┌─────────────────────────────────────┐ │ │
│  │  │   Trust Policy          │ │     │  │         OIDC Provider               │ │ │
│  │  │                         │ │     │  │                                     │ │ │
│  │  │  Principal:             │ │     │  │  https://oidc.eks.us-east-1.        │ │ │
│  │  │   OIDC Provider ────────┼─┼─────┼──►  amazonaws.com/id/72FFDE...         │ │ │
│  │  │                         │ │     │  │                                     │ │ │
│  │  │  Conditions:            │ │     │  └─────────────────────────────────────┘ │ │
│  │  │   - Audience: sts...    │ │     │                                          │ │
│  │  │   - Subject: system:    │ │     └─────────────────────────────────────── ──┘ │
│  │  │     serviceaccount:...  │ │                                                  │
│  │  └─────────────────────────┘ │                                                  │
│  │                              │                                                  │
│  │  ┌─────────────────────────┐ │                                                  │
│  │  │   Inline Policy         │ │                                                  │
│  │  │                         │ │                                                  │
│  │  │  Action:                │ │                                                  │
│  │  │   sts:AssumeRole        │ │─────────────────────────────────────────────    ─┘
│  │  │                         │ │
│  │  │  Resource:              │ │
│  │  │   General Role ARN      │ │
│  │  │                         │ │
│  │  │  Condition:             │ │
│  │  │   ExternalId: external- │ │
│  │  │   dns                   │ │
│  │  └─────────────────────────┘ │
│  └──────────────────────────── ─┘
└────────────────────────────────    ─────────────────────────────────────────────────┘

Flow:
1. Kubernetes ServiceAccount assumes Cluster-Specific Role (via OIDC)
2. Cluster-Specific Role assumes General Role (via STS with ExternalId)
3. General Role provides DNS permissions to ExternalDNS
```

## IAM Role Flow Explained

### 1. **General Role** (`external-dns-yofool`)
- Contains all the DNS permissions needed across multiple clusters
- Has an External ID condition for security: `external-dns`
- Reusable across multiple EKS clusters
- Managed separately from this module

### 2. **Cluster-Specific Role** (`eks-dev-external-dns-role`)
- Created by this module for each cluster
- Trusts the EKS OIDC provider
- Only allows the specific ServiceAccount to assume it
- Has permission to assume the General Role

### 3. **OIDC Integration**
- EKS OIDC provider enables Kubernetes ServiceAccounts to assume AWS IAM roles
- ServiceAccount is annotated with the Cluster-Specific Role ARN
- OIDC trust policy ensures only the correct ServiceAccount can assume the role

### 4. **Role Chaining Flow**
```
ServiceAccount → Cluster Role → General Role → DNS Permissions
    (OIDC)      (sts:AssumeRole)    (Route53)
```

## Features

- **Dual IAM Role Architecture**: Separates cluster-specific trust from reusable permissions
- **OIDC Integration**: Secure authentication without storing AWS credentials
- **Flexible Configuration**: Configurable domain filters, policies, and sources
- **Namespace Management**: Automatically creates and manages Kubernetes namespace
- **Comprehensive Outputs**: Provides all necessary ARNs and configuration details

## Prerequisites

1. **Existing EKS Cluster** with OIDC provider already configured
2. **General IAM Role** with DNS permissions (default: `external-dns-yofool`)
3. **Route53 Hosted Zones** for domains you want to manage

## Usage

```hcl
module "external_dns" {
  source = "./path/to/this/module"

  # Required
  eks_cluster = "eks-dev"
  
  # Optional - IAM Role Configuration
  general_external_dns_role = "external-dns-yofool"  # Your existing general role
  
  # Optional - DNS Configuration
  domain_filters = ["example.com", "dev.example.com"]
  external_dns_policy = "upsert-only"  # or "sync"
  
  # Optional - Deployment Configuration
  namespace = "external-dns"
  addon_version = "v0.18.0-eksbuild.1"
  
  # Optional - Advanced Configuration
  txt_owner_id = "my-cluster-external-dns"
  sources = ["service", "ingress"]
  log_level = "info"
  interval = "1m"
  
  # Optional - AWS Configuration
  aws_default_region = "us-east-1"
  cloud_tags = {
    Environment = "production"
    Team = "platform"
  }
}
```

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `eks_cluster` | string | **required** | Name of the EKS cluster |
| `general_external_dns_role` | string | `"external-dns-yofool"` | Name of existing general ExternalDNS IAM role |
| `domain_filters` | list(string) | `[]` | List of domains that ExternalDNS will manage |
| `external_dns_policy` | string | `"upsert-only"` | ExternalDNS policy: `sync` or `upsert-only` |
| `addon_version` | string | `"v0.18.0-eksbuild.1"` | Version of the ExternalDNS EKS add-on |
| `namespace` | string | `"external-dns"` | Kubernetes namespace for ExternalDNS |
| `txt_owner_id` | string | `null` | Unique identifier (defaults to `{cluster}-external-dns`) |
| `sources` | list(string) | `["service", "ingress"]` | Kubernetes resources to watch |
| `log_level` | string | `"info"` | Log level for ExternalDNS |
| `interval` | string | `"1m"` | Sync interval |
| `aws_default_region` | string | `"us-west-2"` | AWS region |
| `cloud_tags` | map(string) | `{}` | Additional tags for resources |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_external_dns_role_arn` | ARN of the cluster-specific ExternalDNS IAM role |
| `external_dns_addon_arn` | ARN of the ExternalDNS add-on |
| `txt_owner_id` | TXT owner ID used by ExternalDNS |
| `namespace` | Kubernetes namespace where ExternalDNS is deployed |
| `general_role_arn` | ARN of the general ExternalDNS role being used |

## Security Considerations

1. **External ID**: The General Role must require External ID `external-dns` for additional security
2. **OIDC Conditions**: Trust policy strictly limits which ServiceAccount can assume roles
3. **Least Privilege**: Cluster role only has permission to assume the General Role
4. **Resource Isolation**: Each cluster gets its own IAM role for better audit trails

## Troubleshooting

### Common Issues

1. **OIDC Provider Already Exists**
   - The module uses existing OIDC provider, not creating a new one

2. **Invalid Addon Version**
   - Check available versions: `aws eks describe-addon-versions --addon-name external-dns`

3. **Configuration Schema Errors**
   - The module only uses supported configuration parameters for the EKS addon

4. **Permission Denied**
   - Ensure the General Role exists and has proper External ID condition
   - Verify OIDC provider is properly configured

### Debugging Commands

```bash
# Check addon status
kubectl get addon external-dns -n external-dns

# Check ExternalDNS logs
kubectl logs -n external-dns deployment/external-dns

# Verify ServiceAccount annotations
kubectl get serviceaccount external-dns -n external-dns -o yaml

# Test role assumption
aws sts assume-role --role-arn <cluster-role-arn> --role-session-name test
```

## Examples

### Basic Setup
```hcl
module "external_dns" {
  source = "./external-dns"
  eks_cluster = "my-cluster"
}
```

### Production Setup
```hcl
module "external_dns" {
  source = "./external-dns"
  
  eks_cluster = "prod-cluster"
  domain_filters = ["mycompany.com", "api.mycompany.com"]
  external_dns_policy = "sync"
  
  cloud_tags = {
    Environment = "production"
    Team = "platform"
    Cost-Center = "engineering"
  }
}
```

## License

This module is released under the MIT License.
