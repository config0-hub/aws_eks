import json
from config0_publisher.terraform import TFConstructor

def _get_buildspec(stack):

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

    contents = contents_1 + contents_3

    return contents

def run(stackargs):

    import os

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
    stack.add_shelloutconfig("config0-publish:::aws::map-role-aws-to-eks",
                             "map_role")

    stack.add_shelloutconfig("config0-publish:::aws::shellout-with-codebuild",
                             "shellout_codebuild")

    # add substacks
    stack.add_substack("config0-publish:::publish_eks_info")

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

    stack.set_variable("timeout",2700)

    # use the terraform constructor (helper)
    # but this is optional
    tf = TFConstructor(stack=stack,
                       execgroup_name=stack.tf_execgroup.name,
                       provider="aws",
                       resource_name=stack.eks_cluster,
                       resource_type="eks",
                       terraform_type="aws_eks_cluster")

    tf.include(maps={"id": "arn",
                     "cluster_name": "name",
                     "cluster_node_role_arn": "node_role_arn",
                     "cluster_role_arn": "role_arn",
                     "cluster_security_group_ids": "security_group_ids",
                     "cluster_subnet_ids": "subnet_ids",
                     "cluster_endpoint": "endpoint"})

    tf.include(keys=["arn",
                     "name",
                     "platform_version",
                     "version",
                     "node_role_arn"
                     "security_group_ids"
                     "subnet_ids"
                     "role_arn",
                     "vpc_config",
                     "kubernetes_network_config",
                     "endpoint"])

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
            "build_timeout":stack.build_timeout,
            "compute_type": stack.compute_type,
            "image_type": stack.image_type,
            "build_image": stack.build_image,
            "buildspec":_get_buildspec(stack),
        }

        build_env_vars = {
            "EKS_CLUSTER": stack.eks_cluster,
            "EKS_ROLENAME": stack.role_name
        }

        env_vars = { "CODEBUILD_PARAMS_HASH": stack.b64_encode({
            "buildparams": {
                "inputargs":inputargs,
                "env_vars":build_env_vars
            }
        })
        }

        inputargs = {"display": True,
                     "human_description": "Mapping AWS IAM to EKS role with Codebuild",
                     "env_vars": json.dumps(env_vars)}

        stack.shellout_codebuild.run(**inputargs)

    # this is deprecated and replaced with doing it via
    # codebuild b/c of role based permissions
    #if stack.get_attr("role_name"):

    #    # we need the AWS credentials to map role
    #    # though we can in the future make the modes in codebuild
    #    # lambda, but we will need to install eksctl in the worker
    #    # for simplicity, we just do in the config0 worker since
    #    # it's a simple operation
    #    _env_vars = stack.get_tagged_vars(tag="role",
    #                                     output="dict",
    #                                     uppercase=True)

    #    _env_vars["EKS_ROLENAME"] = stack.role_name
    #    _env_vars["AWS_ACCESS_KEY_ID"] = os.environ["AWS_ACCESS_KEY_ID"]
    #    _env_vars["AWS_SECRET_ACCESS_KEY"] = os.environ["AWS_SECRET_ACCESS_KEY"]
    #    _env_vars["DOCKER_EXEC"] = "weaveworks/eksctl:0.82.0"

    #    inputargs = {"display": True,
    #                 "human_description": "Mapping AWS IAM to EKS role",
    #                 "env_vars": json.dumps(_env_vars)}

    #    stack.map_role.run(**inputargs)

    return stack.get_results()
