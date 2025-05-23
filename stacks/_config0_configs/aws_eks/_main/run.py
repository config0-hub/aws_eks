"""
GNU General Public License v3.0
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

class Main(newSchedStack):

    def __init__(self, stackargs):
        newSchedStack.__init__(self, stackargs)

        # docker image to execute terraform with
        self.parse.add_optional(key="tf_runtime",
                                default="tofu:1.9.1",
                                tags="cluster,nodegroups",
                                types="str")

        self.parse.add_required(key="eks_cluster",
                                tags="cluster,nodegroups",
                                types="str")

        self.parse.add_optional(key="aws_default_region",
                                tags="cluster,nodegroups",
                                default="us-west-1")

        self.parse.add_optional(key="eks_cluster_subnet_ids",
                                tags="cluster")

        self.parse.add_optional(key="cloud_tags_hash",
                                tags="cluster,nodegroups",
                                default='null',
                                types="str")

        self.parse.add_optional(key="remote_stateful_bucket",
                                tags="cluster,nodegroups",
                                default='null',
                                types="str,null")

        # add execgroup
        self.stack.add_execgroup("config0-publish:::aws_eks::eks-cluster",
                                 "cloud_resource")

        # add shelloutconfig dependencies
        self.stack.add_shelloutconfig("config0-publish:::aws::map-role-aws-to-eks",
                                      "map_role")

        # add substacks
        self.stack.add_substack("config0-publish:::aws_eks_cluster")
        self.stack.add_substack("config0-publish:::aws_eks_nodegroup")

        # initialize
        self.stack.init_execgroups()
        self.stack.init_substacks()
        self.stack.init_shelloutconfigs()

    def run_eks_cluster(self):
        self.parse.add_required(key="vpc_id",
                                tags="cluster",
                                types="str")

        self.parse.add_required(key="eks_cluster_sg_id",
                                tags="cluster",
                                types="str")

        # mapping eks service account to aws role
        self.parse.add_optional(key="role_name",
                                default="null",
                                tags="cluster",
                                types="str,null")

        self.parse.add_optional(key="eks_cluster_version",
                                default="1.25",
                                tags="cluster",
                                types="float")

        self.parse.add_optional(key="publish_to_saas",
                                default="null",
                                tags="cluster",
                                types="bool")

        # initialize variables and verify
        self.stack.init_variables()
        self.stack.verify_variables()

        default_values = self.stack.get_tagged_vars(tag="cluster",
                                                    output="dict")

        human_description = f"Create EKS cluster {self.stack.eks_cluster}"

        inputargs = {
            "default_values": default_values,
            "automation_phase": "infrastructure",
            "human_description": human_description
        }

        return self.stack.aws_eks_cluster.insert(display=True, **inputargs)

    def run_eks_nodegroup(self):
        self.parse.add_required(key="eks_node_capacity_type",
                                default="ON_DEMAND",
                                choices=["ON_DEMAND", "SPOT"],
                                tags="nodegroups",
                                types="str")

        self.parse.add_required(key="eks_node_ami_type",
                                default="AL2_x86_64",
                                choices=["AL2_x86_64",
                                         "AL2_x86_64_GPU",
                                         "AL2_ARM_64",
                                         "CUSTOM"],
                                tags="nodegroups",
                                types="str")

        self.parse.add_optional(key="eks_node_instance_types",
                                default=["t3.medium"],
                                tags="nodegroups",
                                types="list")

        self.parse.add_optional(key="eks_node_role_arn",
                                default="null",
                                tags="cluster,nodegroups",
                                types="str")

        self.parse.add_optional(key="eks_node_max_capacity",
                                default="2",
                                tags="nodegroups",
                                types="int")

        self.parse.add_optional(key="eks_node_min_capacity",
                                default="1",
                                tags="nodegroups",
                                types="int")

        self.parse.add_optional(key="eks_node_desired_capacity",
                                default="1",
                                tags="nodegroups",
                                types="int")

        self.parse.add_optional(key="eks_node_disksize",
                                default="25",
                                tags="nodegroups",
                                types="int")

        self.parse.add_optional(key="eks_node_group_name",
                                default="null",
                                tags="nodegroups",
                                types="str")

        self.parse.add_optional(key="timeout",
                                tags="nodegroups",
                                default=1800)

        self.parse.add_optional(key="eks_node_group_subnet_ids",
                                tags="nodegroups",
                                default="null")

        self.stack.init_variables()

        if not self.stack.get_attr("eks_node_group_subnet_ids"):
            self.stack.set_variable("eks_node_group_subnet_ids",
                                    self.stack.eks_cluster_subnet_ids)

        if not self.stack.get_attr("eks_node_group_subnet_ids"):
            raise Exception("needs to provide eks_cluster_subnet_ids or eks_node_group_subnet_ids")

        self.stack.verify_variables()

        default_values = self.stack.get_tagged_vars(tag="nodegroups",
                                                    output="dict")

        human_description = f"Create EKS nodegroup {self.stack.eks_cluster}"

        inputargs = {"default_values": default_values,
                     "automation_phase": "infrastructure",
                     "human_description": human_description}

        return self.stack.aws_eks_nodegroup.insert(display=True, **inputargs)

    def run(self):
        self.stack.unset_parallel(sched_init=True)
        self.add_job("eks_cluster")
        self.add_job("eks_nodegroup")

        return self.finalize_jobs()

    def schedule(self):
        sched = self.new_schedule()
        sched.job = "eks_cluster"
        sched.archive.timeout = 3600
        sched.archive.timewait = 120
        sched.conditions.retries = 1
        sched.automation_phase = "infrastructure"
        sched.human_description = "Create EKS cluster"
        sched.on_success = ["eks_nodegroup"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "eks_nodegroup"
        sched.archive.timeout = 3600
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Create EKS nodegroup"
        self.add_schedule()

        return self.get_schedules()