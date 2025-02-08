**Description**
  - This stack publishes the EKS for the Config0 dashboard
  - It is meant to be called by stack that installs EKS
  - Not to be called directly in the config0.yml

**Required**

| argument      | description                            | var type | default      |
| ------------- | -------------------------------------- | -------- | ------------ |
| eks_cluster   | name of the eks                 | string   | None         |

**Example - called in a stack**
```
default_values = {"eks_cluster":stack.eks_cluster}
inputargs = {"default_values":default_values}
inputargs["automation_phase"] = "infrastructure"
inputargs["human_description"] = 'Publish EKS info {}'.format(stack.eks_cluster)
stack.publish_eks_info.insert(display=True,**inputargs)
```
