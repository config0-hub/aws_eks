# AWS EKS ArgoCD CRDs Installation

This stack installs ArgoCD Custom Resource Definitions (CRDs) on an existing AWS EKS cluster, enabling GitOps-based application deployment and management.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Dependencies

### Substacks
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::install-argocd-crds](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/install-argocd-crds)

## Infrastructure

- Installs ArgoCD Custom Resource Definitions (CRDs) on an EKS cluster
- Creates necessary Kubernetes namespace for ArgoCD
- Prepares the cluster for GitOps-based application deployment

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| eks_cluster | The name of the EKS cluster | string | - | yes |
| argocd_namespace | Kubernetes namespace for ArgoCD | string | "argocd" | no |
| aws_default_region | The AWS region | string | "eu-west-1" | no |

## Notes

- The stack uses a Terraform constructor to configure and apply the ArgoCD CRDs
- Default timeout is set to 800 seconds
- The resource name is constructed as `{eks_cluster}-argocd-crds`
- This stack only installs the CRDs needed for ArgoCD operation and may need to be followed by a full ArgoCD installation
