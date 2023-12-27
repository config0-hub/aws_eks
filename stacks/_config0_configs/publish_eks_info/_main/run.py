def run(stackargs):

    # instantiate stack
    stack = newStack(stackargs)

    # add variables
    stack.parse.add_required(key="eks_cluster")

    # init the stack namespace
    stack.init_variables()

    keys2pass = ["endpoint",
                 "arn",
                 "role_arn"]

    _vars = stack.dict_to_dict(
        keys2pass, {}, _info, addNone=None, ignoreNone=True)

    _vpc_info = _info["vpc_config"][0]

    keys2pass = ["cluster_security_group_id'",
                 "vpc_id"]

    stack.dict_to_dict(keys2pass,
                       _vars,
                       _vpc_info,
                       addNone=None,
                       ignoreNone=True)

    _vars["public_access_cidrs"] = ','.join(_vpc_info["public_access_cidrs"])
    _vars["security_group_ids"] = ','.join(_vpc_info["security_group_ids"])
    _vars["subnet_ids"] = ','.join(_vpc_info["subnet_ids"])

    _public_vars = {}

    for _k, _v in _vars.items():
        _key = "eks-{}".format(_k)
        _public_vars[_key] = _v

    stack.publish(_public_vars)

    return stack.get_results()
