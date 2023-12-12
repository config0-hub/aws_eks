**Description**
  - The stack creates EKS in an existing VPC created in a config0.yml launch yaml.

**Infrastructure**

  - expects an existing VPC created in a config0.yml launch yaml. the stack will query the Config0 resources table to get the VPC parameters

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
infrastructure:
   eks:
       stack_name: config0-hub:::aws_eks_dev
       arguments:
          eks_cluster: eval-config0-eks
          role_name: eval-config0-role
          vpc_name: eval-config0-vpc
          vpc_id: vpc-0e3ee770c8758be15
          subnet_ids: subnet-045721f387afabc72,subnet-05075171b106721ad,subnet-0a5e767ac278c437a
          eks_min_capacity: 1
          eks_max_capacity: 1
          eks_desired_capacity: 1
```

**Sample launch with labels and selectors**

```
global_arguments:
   aws_default_region: eu-west-2
labels:
   general:
     environment: dev
     purpose: test
   infrastructure:
     cloud: aws
     product: k8
selectors:
   vpc_info:
     match_labels:
       car: bmw
       model: 320i
       environment: dev
       app_tier: networking
     match_keys:
       provider: aws
       region: eu-west-2
     match_params:
       must_exists: True
       resource_type: vpc
   subnet_info:
     match_labels:
       car: bmw
       model: 320i
       environment: dev
       app_tier: networking
     match_keys:
       provider: aws
       region: eu-west-2
       name: private
     match_params:
       resource_type: subnet
infrastructure:
   eks:
       stack_name: config0-hub:::aws_eks_dev
       arguments:
          vpc_name: selector:::vpc_info::name
          vpc_id: selector:::vpc_info::vpc_id
          eks_cluster: eval-config0-eks
          role_name: eval-config0-role
          subnet_ids: selector:::subnet_info::subnet_id:csv
          eks_min_capacity: 1
          eks_max_capacity: 1
          eks_desired_capacity: 1
       labels:
          - general
          - infrastructure
       selectors:
         - vpc_info
         - subnet_info

```
