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

    # Add variables
    stack.parse.add_required(key="vpc_name",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="vpc_id",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="subnet_ids")

    # this is required in addition to other sg_ids that will be created
    stack.parse.add_required(key="sg_id",
                             tags="tfvar",
                             types="str")

    stack.parse.add_required(key="eks_cluster",
                             tags="tfvar,role,db,runtime_settings",
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
                             tags="tfvar,role,db,resource,runtime_settings",
                             types="str")

    # codebuild specifications
    stack.parse.add_optional(key="use_codebuild",
                             default=True,
                             types="bool")

    stack.parse.add_optional(key="codebuild_basename",
                            types="str",
                            default="config0-iac")

    stack.parse.add_optional(key="compute_type",
                            types="str",
                            default="BUILD_GENERAL1_SMALL")

    stack.parse.add_optional(key="image_type",
                            types="str",
                            default="LINUX_CONTAINER")

    stack.parse.add_optional(key="build_timeout",
                            types="int",
                            default=900)

    # Add execgroup
    stack.add_execgroup("config0-hub:::aws_eks::eks-cluster",
                        "tf_execgroup")

    # Add substack
    stack.add_substack("config0-hub:::tf_executor")

    # Add shelloutconfig dependencies
    stack.add_shelloutconfig("config0-hub:::aws::map-role-aws-to-eks",
                             "map_role")

    stack.add_shelloutconfig("config0-hub:::aws::shellout-with-codebuild",
                             "shellout_codebuild")

    # add substacks
    stack.add_substack("config0-hub:::publish_eks_info")

    # Initialize
    stack.init_variables()
    stack.init_execgroups()
    stack.init_substacks()
    stack.init_shelloutconfigs()

    stack.set_variable("subnet_ids",
                       stack.to_list(stack.subnet_ids),
                       tags="tfvar",
                       types="list")

    # add some aliases for eks_cluster in both runtime_settings
    # run execution and db values
    stack.set_variable("k8_name",
                       stack.eks_cluster,
                       tags="db,runtime_settings",
                       types="str")

    stack.set_variable("eks_name",
                       stack.eks_cluster,
                       tags="db,runtime_settings",
                       types="str")

    stack.set_variable("build_image",
                       "aws/codebuild/standard:7.0")

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

    # fixfix777
    #if stack.get_attr("publish_to_saas"):
    #    default_values = {"eks_cluster": stack.eks_cluster}
    #    inputargs = {"default_values": default_values}
    #    inputargs["automation_phase"] = "infrastructure"
    #    inputargs["human_description"] = 'Publish EKS info {}'.format(
    #        stack.eks_cluster)
    #    stack.publish_eks_info.insert(display=True, **inputargs)

    # associating/map an AWS role to EKS role
    # the AWS role will be able to run kubectl
    # the AWS* credentials should be root or referenced iam

    if stack.get_attr("role_name") and stack.use_codebuild:

        buildparams = { "codebuild_basename":stack.codebuild_basename,
                        "build_timeout":stack.build_timeout,
                        "compute_type": stack.compute_type,
                        "image_type": stack.image_type,
                        "build_image": stack.build_image,
                        "buildspec":_get_buildspec(stack),
                        "build_env_vars": { "EKS_CLUSTER":stack.eks_cluster,
                                            "EKS_ROLENAME":stack.role_name } }

        env_vars = { "CONFIG0_BUILDPARMS_HASH": stack.b64_encode({ "buildparams":buildparams }) }

        inputargs = {"display": True,
                     "human_description": "Mapping AWS IAM to EKS role with Codebuild",
                     "env_vars": json.dumps(env_vars)}

        stack.shellout_codebuild.run(**inputargs)

    elif stack.get_attr("role_name"):
        _env_vars = stack.get_tagged_vars(tag="role",
                                         output="dict",
                                         uppercase=True)

        _env_vars["EKS_ROLENAME"] = stack.role_name
        _env_vars["AWS_ACCESS_KEY_ID"] = os.environ["AWS_ACCESS_KEY_ID"]
        _env_vars["AWS_SECRET_ACCESS_KEY"] = os.environ["AWS_SECRET_ACCESS_KEY"]
        _env_vars["DOCKER_EXEC"] = "weaveworks/eksctl:0.82.0"

        inputargs = {"display": True,
                     "human_description": "Mapping AWS IAM to EKS role",
                     "env_vars": json.dumps(_env_vars)}

        stack.map_role.run(**inputargs)

    return stack.get_results()