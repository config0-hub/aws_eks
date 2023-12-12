from config0_publisher.terraform import TFConstructor


def _set_eks_node_role_arn(stack):

    if stack.get_attr("eks_node_role_arn"):
        return

    resource_info = stack.get_resource(name=stack.eks_cluster,
                                       resource_type="eks",
                                       must_exists=True)[0]

    stack.set_variable("eks_node_role_arn",
                       resource_info["node_role_arn"],
                       tags="tfvar,db",
                       types="str")


def _set_eks_node_group_name(stack):

    if stack.get_attr("eks_node_group_name"):
        return

    stack.set_variable("eks_node_group_name",
                       "{}-nodegroup-main".format(stack.eks_cluster),
                       tags="tfvar,db",
                       types="str")


def run(stackargs):

    # instantiate authoring stack
    stack = newStack(stackargs)

    stack.parse.add_required(key="eks_cluster",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_required(key="eks_subnet_ids")

    stack.parse.add_required(key="eks_node_capacity_type",
                             default="ON_DEMAND",
                             choices=["ON_DEMAND", "SPOT"],
                             tags="tfvar",
                             types="str")

    stack.parse.add_required(key="eks_node_ami_type",
                             default="AL2_x86_64",
                             choices=["AL2_x86_64", "AL2_x86_64_GPU",
                                      "AL2_ARM_64", "CUSTOM"],
                             tags="tfvar",
                             types="str")

    stack.parse.add_optional(key="eks_node_role_arn",
                             default=None,
                             tags="tfvar",
                             types="str")

    stack.parse.add_optional(key="eks_node_instance_types",
                             default=["t3.medium"],
                             tags="tfvar,db",
                             types="list")

    stack.parse.add_optional(key="eks_node_max_capacity",
                             default="2",
                             tags="tfvar",
                             types="int")

    stack.parse.add_optional(key="eks_node_min_capacity",
                             default="1",
                             tags="tfvar",
                             types="int")

    stack.parse.add_optional(key="eks_node_desired_capacity",
                             default="1",
                             tags="tfvar",
                             types="int")

    stack.parse.add_optional(key="eks_node_group_name",
                             default="null",
                             tags="tfvar,db",
                             types="str")

    stack.parse.add_optional(key="eks_node_disksize",
                             default="25",
                             tags="tfvar",
                             types="int")

    stack.parse.add_optional(key="timeout",
                             default=1800,
                             types="int")

    stack.parse.add_optional(key="aws_default_region",
                             default="eu-west-1",
                             tags="tfvar,resource,db,runtime_settings",
                             types="str")

    # publish_resource -> output_resource_to_ui
    stack.add_substack('config0-hub:::output_resource_to_ui')

    # Add execgroup
    stack.add_execgroup("config0-hub:::aws_eks::eks-nodegroup", "tf_execgroup")

    # Add substack
    stack.add_substack('config0-hub:::tf_executor')

    # Initialize
    stack.init_variables()
    stack.init_execgroups()
    stack.init_shelloutconfigs()
    stack.init_substacks()

    stack.set_variable("eks_subnet_ids",
                       stack.to_list(stack.eks_subnet_ids),
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

    _set_eks_node_group_name(stack)
    _set_eks_node_role_arn(stack)

    # use the terraform constructor (helper)
    # but this is optional
    tf = TFConstructor(stack=stack,
                       execgroup_name=stack.tf_execgroup.name,
                       provider="aws",
                       resource_name=stack.eks_node_group_name,
                       resource_type="k8_node_group",
                       terraform_type="aws_eks_node_group")

    tf.include(maps={"id": "arn"})

    tf.output(keys=["arn"])

    # finalize the tf_executor
    stack.tf_executor.insert(display=True,
                             **tf.get())

    return stack.get_results()
