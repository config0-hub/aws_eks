"""
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

Copyright (C) 2025 Gary Leong <gary@config0.com>
"""

class Main(newSchedStack):

    def __init__(self, stackargs):
        newSchedStack.__init__(self, stackargs)

        # docker image to execute terraform with
        self.parse.add_optional(key="tf_runtime",
                                default="tofu:1.9.1",
                                tags="cluster,base_helm,external_dns,argocd_crds,argocd",
                                types="str")

        self.parse.add_required(key="eks_cluster",
                                tags="cluster,base_helm,external_dns,argocd_crds,argocd",
                                types="str")

        self.parse.add_optional(key="aws_default_region",
                                tags="cluster,base_helm,external_dns,argocd_crds,argocd",
                                default="us-west-1")

        self.parse.add_optional(key="cloud_tags_hash",
                                tags="cluster,base_helm,external_dns,argocd_crds,argocd",
                                default='null',
                                types="str")

        self.parse.add_optional(key="remote_stateful_bucket",
                                tags="cluster,base_helm,external_dns,argocd_crds,argocd",
                                default='null',
                                types="str,null")

        self.parse.add_required(key="general_external_dns_role",
                                tags="external_dns",
                                types="str")

        self.parse.add_required(key="domain_filters",
                                tags="external_dns",
                                types="list")

        self.parse.add_optional(key="external_dns_policy",
                                tags="external_dns",
                                default="upsert-only",
                                choices=["upsert-only","sync"])

        # add substacks
        self.stack.add_substack("config0-publish:::aws_eks_auto")
        self.stack.add_substack("config0-publish:::base_helm_pkgs")
        self.stack.add_substack("config0-publish:::external_dns_addon")
        self.stack.add_substack("config0-publish:::install_argo_crds")
        self.stack.add_substack("config0-publish:::install_argocd")

        # initialize
        self.stack.init_substacks()

    def run_eks_cluster(self):

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

        return self.stack.aws_eks_cluster_auto.insert(display=True, **inputargs)

    def run_base_helm(self):

        # initialize variables and verify
        self.stack.init_variables()
        self.stack.verify_variables()

        default_values = self.stack.get_tagged_vars(tag="base_helm",
                                                    output="dict")

        human_description = f"Create Base Helm {self.stack.eks_cluster}"

        inputargs = {"default_values": default_values,
                     "automation_phase": "infrastructure",
                     "human_description": human_description}

        return self.stack.base_helm_pkgs.insert(display=True, **inputargs)

    def run_external_dns(self):

        # initialize variables and verify
        self.stack.init_variables()
        self.stack.verify_variables()

        default_values = self.stack.get_tagged_vars(tag="external_dns",
                                                    output="dict")

        human_description = f"Install External DNS on {self.stack.eks_cluster}"

        inputargs = {"default_values": default_values,
                     "automation_phase": "infrastructure",
                     "human_description": human_description}

        return self.stack.external_dns_addon.insert(display=True, **inputargs)


    def run_argocd_crds(self):

        # initialize variables and verify
        self.stack.init_variables()
        self.stack.verify_variables()

        default_values = self.stack.get_tagged_vars(tag="argocd_crds",
                                                    output="dict")

        human_description = f"Install ArgoCD CRDS on {self.stack.eks_cluster}"

        inputargs = {"default_values": default_values,
                     "automation_phase": "infrastructure",
                     "human_description": human_description}

        return self.stack.install_argo_crds.insert(display=True, **inputargs)

    def run_argocd(self):

        # initialize variables and verify
        self.stack.init_variables()
        self.stack.verify_variables()

        default_values = self.stack.get_tagged_vars(tag="argocd",
                                                    output="dict")

        human_description = f"Install ArgoCD on {self.stack.eks_cluster}"

        inputargs = {"default_values": default_values,
                     "automation_phase": "infrastructure",
                     "human_description": human_description}

        return self.stack.install_argocd.insert(display=True, **inputargs)

    def run(self):
        self.stack.unset_parallel(sched_init=True)
        self.add_job("eks_cluster")
        self.add_job("base_helm")
        self.add_job("external_dns")
        self.add_job("argocd_crds")
        self.add_job("argocd")

        return self.finalize_jobs()

    def schedule(self):
        sched = self.new_schedule()
        sched.job = "eks_cluster"
        sched.archive.timeout = 3600
        sched.archive.timewait = 120
        sched.conditions.retries = 1
        sched.automation_phase = "infrastructure"
        sched.human_description = "Create EKS cluster"
        sched.on_success = ["base_helm"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "base_helm"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Install Base Helm Packages"
        sched.on_success = ["external_dns"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "external_dns"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Install External DNS"
        sched.on_success = ["argocd_crds"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "argocd_crds"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Install ArgoCD CRDS"
        sched.on_success = ["argocd"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "argocd"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Install ArgoCD"
        self.add_schedule()

        return self.get_schedules()
