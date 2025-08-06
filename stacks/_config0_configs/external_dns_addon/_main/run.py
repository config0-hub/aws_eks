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

    stack.parse.add_required(key="eks_cluster",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="general_external_dns_role",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="domain_filters",
                             tags="tfvar,db",
                             default="null",
                             types="str")

    stack.parse.add_optional(key="external_dns_policy",
                             tags="tfvar,db",
                             default="upsert-only",
                             choices=["upsert-only","sync"])

    stack.parse.add_optional(key="addon_version",
                             default="v0.18.0-eksbuild.1",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_optional(key="internal",
                             default="1m",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_optional(key="namespace",
                             default="external-dns",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_optional(key="aws_default_region",
                             default="eu-west-1",
                             tags="tfvar,db,resource,tf_exec_env",
                             types="str")

    stack.add_execgroup("config0-publish:::aws_eks::external-dns-addon",
                        "tf_execgroup")

    # Add substack
    stack.add_substack("config0-publish:::tf_executor")

    # Initialize
    stack.init_variables()
    stack.init_execgroups()
    stack.init_substacks()

    # Verify variables after initialization
    stack.verify_variables()

    stack.set_variable("timeout", 800)

    # use the terraform constructor (helper)
    # but this is optional
    tf = TFConstructor(stack=stack,
                       execgroup_name=stack.tf_execgroup.name,
                       provider="aws",
                       resource_name=f'{stack.eks_cluster}-external-dns',
                       resource_type="k8s-pkgs")

    tf.include(values={
        "aws_default_region": stack.aws_default_region,
        "role_name": stack.general_external_dns_role,
        "name": f'{stack.eks_cluster}-external-dns',
    })

    # finalize the tf_executor
    stack.tf_executor.insert(display=True,
                             **tf.get())

    return stack.get_results()
