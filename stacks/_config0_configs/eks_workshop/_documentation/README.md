**Description**
  - The stack scaffolds the setup for the AWS EKS workshop
  - Instead of a cloud9 instance, this stack will create an EC2 instance to ssh into for the workshop

**Infrastructure**

  - expects an existing VPC created in a config0.yml launch yaml. 
  - the stack will query the Config0 resources table to get the VPC parameters

**Required**

| argument      | description                            | var type | default      |
| ------------- | -------------------------------------- | -------- | ------------ |
| vpc_name   | name of the vpc                 | string   | None         |
| vpc_id   | id of the vpc                 | string   | None         |
| subnet_ids   | the subnet_ids separated by comma - csv | string   | None         |
| sg_id   | the security group for EKS instance | string   | None         |
| bastion_sg_id   | the bastion security group for ec2 instance | string   | None         |
| workshop_name   | the name of the workshop | string   | None         |

**Optional**

| argument           | description                            | var type |  default      |
| ------------- | -------------------------------------- | -------- | ------------ |
| aws_default_region   | the default aws region               | string   | us-west-1         |
| eks_node_min_capacity   | the min capacity of the eks cluster               | string   | 1         |
| eks_node_max_capacity   | the max capacity of the eks cluster               | string   | 1         |
| eks_node_desired_capacity   | the desired capacity of the eks cluster               | string   | 1         |
| eks_instance_type   | the instance_type for the ec2 instance used to get through the workshop| string   | t3.micro         |
| disksize   | the disksize for the ec2 instance used to get through the workshop| string   | 25         |

**Sample entry**
```
