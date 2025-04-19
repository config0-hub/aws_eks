'''
Copyright (C) 2025 Gary Leong <gary@config0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
'''

import json
from config0_publisher.terraform import TFConstructor


def _get_buildspec():

    contents_1 = '''version: 0.2
phases:
  install:
    on-failure: ABORT
    commands:
      - echo "Installing kubectl ..."
      - curl --silent --location -o /tmp/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
      - chmod +x /tmp/kubectl
      - echo "Installing eksctl ..."
      - curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
      - chmod +x /tmp/eksctl

'''

    contents_3 = '''
  build:
    on-failure: ABORT
    commands:
      - export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
      - export EKS_ROLEARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_ROLENAME}
      - /tmp/eksctl create iamidentitymapping --cluster ${EKS_CLUSTER} --arn ${EKS_ROLEARN} --group system:masters --username admin
'''

    return contents_1 + contents_3


def run(stackargs):

    # instantiate authoring stack
    stack = newStack(stackargs)

    stack.parse.add_required(key="vpc_id",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="eks_cluster_subnet_ids")

    # this is required in addition to other sg_ids that will be created
    stack.parse.add_required(key="eks_cluster_sg_id",
                             tags="tfvar",
                             types="str")

    stack.parse.add_required(key="eks_cluster",
                             tags="tfvar,role,db,tf_exec_env",
                             types="str")

    stack.parse.add_optional(key="eks_cluster_version",
                             default="1.25",
                             tags="tfvar,db",
                             types="float")

    # mapping eks service account to aws role
    stack.parse.add_optional(key="role_name",
                             default=None,
                             types="str")

    stack.parse.add_optional(key="aws_default_region",
                             default="eu-west-1",
                             tags="tfvar,role,db,resource,tf_exec_env",
                             types="str")

    stack.parse.add_optional(key="compute_type",
                             types="str",
                             default="BUILD_GENERAL1_SMALL")

    stack.parse.add_optional(key="image_type",
                             types="str",
                             default="LINUX_CONTAINER")

    # Add execgroup
    stack.add_execgroup("config0-publish:::aws_eks::eks-cluster",
                        "tf_execgroup")

    # Add substack
    stack.add_substack("config0-publish:::tf_executor")

    # Add shelloutconfig dependencies
    stack.add_shelloutconfig("config0-publish:::aws::shellout-with-codebuild",
                             "shellout_codebuild")

    # Initialize
    stack.init_variables()
    stack.init_execgroups()
    stack.init_substacks()
    stack.init_shelloutconfigs()

    stack.set_variable("eks_cluster_subnet_ids",
                       stack.to_list(stack.eks_cluster_subnet_ids),
                       tags="tfvar",
                       types="list")

    # add some aliases for eks_cluster in both tf_exec_env
    # run execution and db values
    stack.set_variable("k8_name",
                       stack.eks_cluster,
                       tags="db,tf_exec_env",
                       types="str")

    stack.set_variable("eks_name",
                       stack.eks_cluster,
                       tags="db,tf_exec_env",
                       types="str")

    stack.set_variable("build_image",
                       "aws/codebuild/standard:7.0")

    stack.set_variable("build_timeout", 2700)

    # use the terraform constructor (helper)
    # but this is optional
    tf = TFConstructor(stack=stack,
                       execgroup_name=stack.tf_execgroup.name,
                       provider="aws",
                       resource_name=stack.eks_cluster,
                       resource_type="eks")

    tf.include(values={
        "aws_default_region": stack.aws_default_region,
        "name": stack.eks_cluster
    })

    # this will need to be correspond to those
    # in the output section
    tf.include(maps={"id": "arn",
                     "cluster_node_role_arn": "node_role_arn",
                     "cluster_role_arn": "role_arn",
                     "cluster_security_group_ids": "security_group_ids",
                     "cluster_subnet_ids": "subnet_ids",
                     "cluster_endpoint": "endpoint"})

    tf.output(keys=["endpoint",
                    "arn",
                    "cluster_security_group_ids",
                    "cluster_subnet_ids",
                    "cluster_role_arn",
                    "cluster_node_role_arn"])

    # finalize the tf_executor
    stack.tf_executor.insert(display=True,
                             **tf.get())

    if stack.get_attr("role_name"):

        inputargs = {
            "build_timeout": stack.build_timeout,
            "compute_type": stack.compute_type,
            "image_type": stack.image_type,
            "build_image": stack.build_image,
            "buildspec": _get_buildspec(),
        }

        build_env_vars = {
            "EKS_CLUSTER": stack.eks_cluster,
            "EKS_ROLENAME": stack.role_name
        }

        env_vars = {"CODEBUILD_PARAMS_HASH": stack.b64_encode({
            "buildparams": {
                "inputargs": inputargs,
                "env_vars": build_env_vars
            }
        })}

        inputargs = {"display": True,
                     "human_description": "Mapping AWS IAM to EKS role with Codebuild",
                     "env_vars": json.dumps(env_vars)}

        stack.shellout_codebuild.run(**inputargs)

    return stack.get_results()