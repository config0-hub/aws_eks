**Description**

  - This stack provisions an EKS cluster and EKS nodegroups within an existing VPC.

**Infrastructure**

  - This stack assumes that the VPC parameters are present in the Config0 resource database.

**Required**

| argument      | description                            | var type | default      |
| ------------- | -------------------------------------- | -------- | ------------ |
| vpc_name   | name of the vpc                 | string   | None         |
| vpc_id   | id of the vpc                 | string   | None         |
| eks_cluster   | the name given to the eks cluster | string   | None         |
| role_name   | the aws role_name to access the eks cluster | string   | None         |
| subnet_ids   | the subnet_ids separated by comma - csv | string   | None         |

**Optional**

| argument           | description                            | var type |  default      |
| ------------- | -------------------------------------- | -------- | ------------ |
| aws_default_region   | the default aws region               | string   | us-west-1         |
| eks_min_capacity   | the min capacity of the eks cluster               | string   | 1         |
| eks_max_capacity   | the max capacity of the eks cluster               | string   | 1         |
| eks_desired_capacity   | the desired capacity of the eks cluster               | string   | 1         |
| eks_tf_release   | the Terraform EKS release template               | string   | v17.20.0         |
| cloud_tags_hash | the tags for the resources in the cloud as base64 | string  | None         |

**Sample entry**

```
```
