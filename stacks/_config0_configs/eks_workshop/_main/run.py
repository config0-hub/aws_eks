def _get_user_data(stack):

    contents = '''#!/bin/bash

curl --silent --location -o /usr/local/bin/kubectl \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl

chmod +x /usr/local/bin/kubectl

curl --silent --location -o /usr/local/bin/kubectl \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl

chmod +x /usr/local/bin/kubectl

# sudo yum -y install jq gettext bash-completion moreutils
apt-get update && apt-get install awscli jq gettext bash-completion moreutils docker docker-compose -y

echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

for command in kubectl jq envsubst aws
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done

kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

echo 'export LBC_VERSION="v2.3.0"' >>  ~/.bash_profile
.  ~/.bash_profile

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv -v /tmp/eksctl /usr/local/bin

eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add stable https://charts.helm.sh/stable

helm completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
source <(helm completion bash)

echo "#######################"
echo "# Tools versions"
echo "#######################"
echo ""
echo "AWS"
aws --version
echo ""
echo "KubeCtl"
kubectl version
echo ""
echo "EKSCtl"
eksctl version
echo ""
echo "Helm"
helm version --short
echo "#######################"
'''

    _contents = '''

# eks workshop

mkdir ~/environment
cd ~/environment
git clone https://github.com/aws-containers/ecsdemo-frontend.git
git clone https://github.com/aws-containers/ecsdemo-nodejs.git
git clone https://github.com/aws-containers/ecsdemo-crystal.git

# FIXME
aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile

'''

    contents = contents + _contents

    # FIXME
    _contents = '''
aws eks update-kubeconfig --region {} --name {}
echo "aws eks update-kubeconfig --region {} --name {}" > /root/update-kubeconfig.sh
'''.format(stack.aws_default_region,
           stack.eks_cluster,
           stack.aws_default_region,
           stack.eks_cluster)

# export DASHBOARD_VERSION="v2.0.0"
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
# kubectl proxy --port=8080 --address=0.0.0.0 --disable-filter=true &

# kill proxy
# pkill -f 'kubectl proxy --port=8080'

# delete dashboard
# kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
# unset DASHBOARD_VERSION

    contents = contents + _contents

    return contents


class Main(newSchedStack):

    def __init__(self, stackargs):

        newSchedStack.__init__(self, stackargs)

        # Add default variables
        self.parse.add_required(key="vpc_name")
        self.parse.add_required(key="vpc_id")
        self.parse.add_required(key="subnet_ids")
        self.parse.add_required(key="sg_id")
        self.parse.add_required(key="bastion_sg_id")
        self.parse.add_required(key="workshop_name")

        self.parse.add_required(key="eks_cluster_version",
                                default="1.25")

        # docker image to execute terraform with
        self.parse.add_optional(key="aws_default_region",
                                default="us-west-1")

        self.parse.add_optional(key="eks_node_min_capacity",
                                default="1")

        self.parse.add_optional(key="eks_node_max_capacity",
                                default="2")

        self.parse.add_optional(key="eks_node_desired_capacity",
                                default="1")

        self.parse.add_optional(key="eks_node_instance_types",
                                default=["t3.micro"])

        self.parse.add_optional(key="eks_node_capacity_type",
                                default="SPOT")

        self.parse.add_optional(key="eks_node_ami_type",
                                default="AL2_x86_64")

        self.parse.add_optional(key="eks_node_role_arn",
                                default="null")

        self.parse.add_optional(key="admin_instance_type",
                                default="t3.micro")

        self.parse.add_optional(key="disksize",
                                default="25")

        self.parse.add_optional(key="spot",
                                default="null")

        # Add substack
        self.stack.add_substack('config0-hub:::ec2_ssh_upload')
        self.stack.add_substack('config0-hub:::aws_iam_role')
        self.stack.add_substack('config0-hub:::aws_eks')
        self.stack.add_substack('config0-hub:::ec2_ubuntu_admin')

        self.stack.init_substacks()

    def run_sshkey(self):

        self.stack.init_variables()
        # ssh public key to insert into ec2 admin
        self.stack.set_variable(
            "ssh_key_name", "{}-public-key".format(self.stack.workshop_name))

        overide_values = {"key_name": self.stack.ssh_key_name}
        default_values = {"aws_default_region": self.stack.aws_default_region}

        inputargs = {"default_values": default_values,
                     "overide_values": overide_values}

        inputargs["automation_phase"] = "infrastructure"
        inputargs["human_description"] = 'Upload user ssh public {}'.format(
            self.stack.ssh_key_name)

        return self.stack.ec2_ssh_upload.insert(display=True, **inputargs)

    def run_iam_role(self):

        self.stack.init_variables()

        self.stack.set_variable("role_name", 
                                "{}-role".format(self.stack.workshop_name))

        self.stack.set_variable("iam_instance_profile",
                                "{}-profile".format(self.stack.workshop_name))

        self.stack.set_variable("iam_role_policy_name",
                                "{}-policy".format(self.stack.workshop_name))

        overide_values = {"role_name": self.stack.role_name,
                          "iam_instance_profile": self.stack.iam_instance_profile,
                          "iam_role_policy_name": self.stack.iam_role_policy_name
                          }

        default_values = {"aws_default_region": self.stack.aws_default_region}

        inputargs = {"default_values": default_values,
                     "overide_values": overide_values}

        inputargs["automation_phase"] = "infrastructure"
        inputargs["human_description"] = 'Create IAM role for {}'.format(
            self.stack.workshop_name)

        return self.stack.aws_iam_role.insert(display=True, **inputargs)

    def run_eks(self):

        self.stack.init_variables()

        self.stack.set_variable("role_name", 
                                "{}-role".format(self.stack.workshop_name))

        self.stack.set_variable("eks_cluster", 
                                "{}-eks-cluster".format(self.stack.workshop_name))

        overide_values = {"role_name": self.stack.role_name,
                          "eks_cluster": self.stack.eks_cluster,
                          "eks_cluster_version": self.stack.eks_cluster_version,
                          "eks_subnet_ids": self.stack.subnet_ids,
                          "publish_to_saas": True}

        if self.stack.get_attr("eks_node_role_arn"):
            overide_values["eks_node_role_arn"] = self.stack.eks_node_role_arn

        default_values = {"vpc_name": self.stack.vpc_name,
                          "vpc_id": self.stack.vpc_id,
                          "eks_node_capacity_type": self.stack.eks_node_capacity_type,
                          "eks_node_ami_type": self.stack.eks_node_ami_type,
                          "subnet_ids": self.stack.subnet_ids,
                          "sg_id": self.stack.sg_id,
                          "eks_node_min_capacity": self.stack.eks_node_min_capacity,
                          "eks_node_max_capacity": self.stack.eks_node_max_capacity,
                          "eks_node_desired_capacity": self.stack.eks_node_desired_capacity,
                          "eks_node_instance_types": self.stack.eks_node_instance_types,
                          "aws_default_region": self.stack.aws_default_region
                          }

        inputargs = {"default_values": default_values,
                     "overide_values": overide_values}

        inputargs["automation_phase"] = "infrastructure"
        inputargs["human_description"] = 'Create EKS cluster {}'.format(
            self.stack.eks_cluster)

        return self.stack.aws_eks.insert(display=True, **inputargs)

    def run_vm_admin(self):

        self.stack.init_variables()

        self.stack.set_variable("hostname", 
                                "{}-admin".format(self.stack.workshop_name))

        self.stack.set_variable("eks_cluster", 
                                "{}-eks-cluster".format(self.stack.workshop_name))

        # ssh public key to insert into ec2 admin
        self.stack.set_variable("ssh_key_name", 
                                "{}-public-key".format(self.stack.workshop_name))

        self.stack.set_variable("iam_instance_profile",
                                "{}-profile".format(self.stack.workshop_name))

        user_data_hash = self.stack.b64_encode(_get_user_data(self.stack))

        overide_values = {"hostname": self.stack.hostname,
                          "spot": None,
                          "ip_key": "public_ip",
                          "user_data_hash": user_data_hash,
                          "ssh_key_name": self.stack.ssh_key_name,
                          "iam_instance_profile": self.stack.iam_instance_profile,
                          "publish_to_saas": True}

        if self.stack.get_attr("spot"):
            overide_values["spot"] = self.stack.spot

        default_values = {"vpc_name": self.stack.vpc_name,
                          "vpc_id": self.stack.vpc_id,
                          "subnet_ids": self.stack.subnet_ids,
                          "size": self.stack.admin_instance_type,
                          "disksize": self.stack.disksize,
                          "aws_default_region": self.stack.aws_default_region,
                          "sg_id": self.stack.bastion_sg_id,
                          }

        inputargs = {"default_values": default_values,
                     "overide_values": overide_values}

        inputargs["automation_phase"] = "infrastructure"
        inputargs["human_description"] = 'Create EC2 admin {}'.format(
            self.stack.hostname)

        return self.stack.ec2_ubuntu_admin.insert(display=True, **inputargs)

    def run(self):

        self.stack.unset_parallel()
        self.add_job("sshkey")
        self.add_job("iam_role")
        self.add_job("eks")
        self.add_job("vm_admin")

        return self.finalize_jobs()

    def schedule(self):

        sched = self.new_schedule()
        sched.job = "sshkey"
        sched.archive.timeout = 1200
        sched.archive.timewait = 120
        sched.conditions.retries = 1
        sched.automation_phase = "infrastructure"
        sched.human_description = "upload user public ssh key"
        sched.on_success = ["iam_role"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "iam_role"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Create IAM role"
        sched.on_success = ["eks"]
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "eks"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.on_success = ["vm_admin"]
        sched.human_description = "Create EKS for workshop"
        self.add_schedule()

        sched = self.new_schedule()
        sched.job = "vm_admin"
        sched.archive.timeout = 1800
        sched.archive.timewait = 120
        sched.automation_phase = "infrastructure"
        sched.human_description = "Create EC2 for workshop"
        self.add_schedule()

        return self.get_schedules()
