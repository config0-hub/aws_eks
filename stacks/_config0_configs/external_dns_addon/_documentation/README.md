# AWS EKS External DNS Addon

This stack installs and configures the External DNS addon for an existing AWS EKS cluster, allowing automatic management of DNS records for Kubernetes services.

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Dependencies

### Substacks
- [config0-publish:::tf_executor](https://api-app.config0.com/web_api/v1.0/stacks/config0-publish/tf_executor)

### Execgroups
- [config0-publish:::aws_eks::external-dns-addon](https://api-app.config0.com/web_api/v1.0/exec/groups/config0-publish/aws_eks/external-dns-addon)

## Infrastructure

- Installs External DNS addon on an EKS cluster
- Configures IAM role for External DNS access to Route 53
- Sets up domain filtering for DNS record management

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| eks_cluster | The name of the EKS cluster | string | - | yes |
| general_external_dns_role | IAM role name for External DNS | string | - | yes |
| domain_filters | List of domains to manage DNS records for | list | - | yes |
| external_dns_policy | DNS record update policy | string | "upsert-only" | no |
| addon_version | External DNS addon version | string | "v0.18.0-eksbuild.1" | no |
| internal | Internal setting (likely an interval) | string | "1m" | no |
| namespace | Kubernetes namespace for External DNS | string | "external-dns" | no |
| aws_default_region | The AWS region | string | "eu-west-1" | no |

## Notes

- The stack uses a Terraform constructor to configure and apply the External DNS addon
- Default timeout is set to 800 seconds
- The External DNS policy can be set to either "upsert-only" (only create or update records) or "sync" (also delete records)
- The resource name is constructed as `{eks_cluster}-external-dns`
