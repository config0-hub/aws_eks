# AWS EKS Base Helm Packages

This stack installs base Helm packages on an existing AWS EKS cluster, including metrics server and Prometheus/Grafana monitoring tools.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Dependencies

### Substacks
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::base-helm-pkgs](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/base-helm-pkgs)

## Infrastructure

- Installs metrics-server (optional)
- Installs Prometheus and Grafana (optional)
- Applies Helm charts to an existing EKS cluster

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| eks_cluster | The name of the EKS cluster | string | - | yes |
| aws_default_region | The AWS region | string | eu-west-1 | no |
| install_metrics_server | Whether to install the metrics server | string | "true" | no |
| install_prometheus_grafana | Whether to install Prometheus and Grafana | string | "true" | no |

## Notes

- The stack uses a Terraform constructor to configure and apply the Helm packages
- Default timeout is set to 800 seconds
- Both metrics_server and prometheus_grafana installations can be disabled by setting them to "null", None, or "None"
