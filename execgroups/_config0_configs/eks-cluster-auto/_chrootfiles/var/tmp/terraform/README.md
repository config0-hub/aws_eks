---

# **Summary of the Terraform Code**

This Terraform code provisions an **Amazon Elastic Kubernetes Service (EKS)** cluster in AWS, along with the necessary **IAM roles and policies** for managing the cluster and its worker nodes. It dynamically discovers VPC subnets, tags them appropriately for Kubernetes, and configures the cluster for private or public API access. Below is a detailed breakdown:

---

## **1. Data Lookup for VPC and Subnets**

### **VPC Lookup**

```hcl
data "aws_vpc" "eks" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}
```

- **`data.aws_vpc`**: Fetches the VPC based on its name (provided as the variable `vpc_name`).
- This allows the code to dynamically retrieve the VPC ID without hardcoding it.

---

### **Private and Public Subnet Lookup**

```hcl
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}
```

- **`data.aws_subnets.private`**: Retrieves private subnets in the VPC by filtering subnet tags containing the word `private`.
- **`data.aws_subnets.public`**: Retrieves public subnets in the VPC by filtering subnet tags containing the word `public`.
- This dynamic lookup avoids hardcoding subnet IDs, making the configuration reusable.

---

## **2. Subnet Tagging for Kubernetes**

### **Tagging All Subnets**

```hcl
resource "aws_ec2_tag" "subnet_tags" {
  for_each = toset(local.all_subnet_ids)

  resource_id = each.key
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}
```

- Tags **all subnets** (both private and public) with `kubernetes.io/cluster/<cluster_name>`, allowing Kubernetes to recognize these subnets for use.

---

### **Tagging Private Subnets**

```hcl
resource "aws_ec2_tag" "private_subnet_tags" {
  for_each = toset(data.aws_subnets.private.ids)

  resource_id = each.key
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
```

- Tags private subnets with `kubernetes.io/role/internal-elb` to indicate they should be used for **internal load balancers**.

---

### **Tagging Public Subnets**

```hcl
resource "aws_ec2_tag" "public_subnet_tags" {
  for_each = toset(data.aws_subnets.public.ids)

  resource_id = each.key
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
```

- Tags public subnets with `kubernetes.io/role/elb` to indicate they should be used for **external load balancers**.

---

## **3. Security Group for the EKS Cluster**

```hcl
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for the EKS cluster"
  vpc_id      = data.aws_vpc.eks.id

  ingress {
    description = "Allow Kubernetes API access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.use_private_subnets ? [] : ["YOUR_LAPTOP_PUBLIC_IP/32"]
  }

  ingress {
    description = "Allow worker nodes to communicate with the control plane"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

- **Ingress Rules**:
  - Allows API access (port `443`) from either private networks (if `use_private_subnets = true`) or your laptop's public IP.
  - Allows worker nodes to communicate with the control plane on ports `1025-65535`.
- **Egress Rules**:
  - Allows all outbound traffic.

---

## **4. EKS Cluster Provisioning**

```hcl
resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = local.default_subnet_ids
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = var.use_private_subnets
    endpoint_public_access  = !var.use_private_subnets
    public_access_cidrs     = var.use_private_subnets ? [] : ["YOUR_LAPTOP_PUBLIC_IP/32"]
  }
}
```

- **`subnet_ids`:** Dynamically selects private or public subnets based on `use_private_subnets`.
- **`endpoint_private_access` and `endpoint_public_access`:** Toggles access to the Kubernetes API server based on whether private or public subnets are used.

---

## **5. IAM Roles for the Cluster**

### **Cluster Role**

```hcl
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.cluster_role_assume_role_policy.json
}
```

- Creates an IAM role for the EKS cluster with an **assume role policy** that allows the EKS service to assume this role.

---

### **Node Role**

```hcl
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
```

- Creates an IAM role for worker nodes, allowing EC2 instances to assume this role.

---

## **6. Policy Attachments**

### **Cluster Role Policies**

```hcl
resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])

  policy_arn = each.key
  role       = aws_iam_role.cluster.name
}
```

- Attaches policies to the cluster IAM role for managing the cluster and VPC resources.

---

### **Node Role Policies**

```hcl
resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ])

  policy_arn = each.key
  role       = aws_iam_role.node.name
}
```

- Attaches policies to the node IAM role for:
  - Managing worker nodes.
  - Pulling images from Amazon ECR.
  - Configuring the Container Network Interface (CNI).

---

## **7. Local Variables**

```hcl
locals {
  all_subnet_ids    = concat(data.aws_subnets.private.ids, data.aws_subnets.public.ids)
  default_subnet_ids = var.use_private_subnets ? data.aws_subnets.private.ids : data.aws_subnets.public.ids
}
```

- Combines private and public subnet IDs for tagging.
- Dynamically selects default subnets based on the `use_private_subnets` variable.

---

## **Conclusion**

This Terraform code:
1. Dynamically discovers VPC and subnet resources.
2. Tags subnets for Kubernetes use, supporting both private and public workloads.
3. Creates an EKS cluster with flexible networking configurations.
4. Provides minimal yet sufficient IAM roles, policies, and security groups.
