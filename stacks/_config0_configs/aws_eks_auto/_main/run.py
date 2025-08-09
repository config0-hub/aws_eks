"""
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
"""

import json
from config0_publisher.terraform import TFConstructor


def run(stackargs):

    # instantiate authoring stack
    stack = newStack(stackargs)

    stack.parse.add_required(key="vpc_name",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="role_names",
                             default="config0-iac-codebuild-role,config0-iac-lambda-role",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="eks_cluster",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_optional(key="aws_default_region",
                             default="eu-west-1",
                             tags="tfvar,role,db,resource,tf_exec_env",
                             types="str")

    # Add execgroup
    stack.add_execgroup("config0-publish:::aws_eks::eks-cluster-auto",
                        "tf_execgroup")

    # Add substack
    stack.add_substack("config0-publish:::tf_executor")

    # Initialize
    stack.init_variables()
    stack.init_execgroups()
    stack.init_substacks()

    # Verify variables after initialization
    stack.verify_variables()

    stack.set_variable("timeout", 1800)

    # use the terraform constructor (helper)
    # but this is optional
    tf = TFConstructor(stack=stack,
                       execgroup_name=stack.tf_execgroup.name,
                       provider="aws",
                       resource_name=stack.eks_cluster,
                       resource_type="eks")

    tf.include(values={
        "aws_default_region": stack.aws_default_region,
        "auto_mode": True,
        "name": stack.eks_cluster
    })

    # this will need to be correspond to those
    # in the output section
    tf.output(keys=["cluster_endpoint",
                    "arn",
                    "cluster_security_group_id",
                    "cluster_role_arn",
                    "oidc_provider_arn",
                    "node_role_arn"])

    # finalize the tf_executor
    stack.tf_executor.insert(display=True,
                             **tf.get())

    return stack.get_results()
