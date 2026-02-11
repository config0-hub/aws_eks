# AWS EKS ArgoCD Installation

This stack installs ArgoCD on an existing AWS EKS cluster, providing a GitOps continuous delivery tool for Kubernetes.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Dependencies

### Substacks
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::install-argocd](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/install-argocd)

## Infrastructure

- Installs ArgoCD on an EKS cluster
- Deploys ArgoCD from a Helm chart
- Configures the necessary Kubernetes namespace

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| eks_cluster | The name of the EKS cluster | string | - | yes |
| argocd_namespace | Kubernetes namespace for ArgoCD | string | "argocd" | no |
| aws_default_region | The AWS region | string | "eu-west-1" | no |
| argocd_chart_version | The version of the ArgoCD Helm chart | string | "7.1.3" | no |
| argocd_chart_repo_url | The URL of the ArgoCD Helm chart repository | string | "https://argoproj.github.io/argo-helm" | no |

## Notes

- The stack uses a Terraform constructor to configure and deploy ArgoCD
- Default timeout is set to 800 seconds
- The resource name is constructed as `{eks_cluster}-argocd`
- ArgoCD enables GitOps-style continuous delivery for Kubernetes applications
