resource "aws_eks_cluster" "eks" {

  count    = var.is_eks_cluster_enabled == true ? 1 : 0
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[count.index].arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = [aws_subnet.private1.id,aws_subnet.private2.id]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }


  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name = var.cluster_name
    Env  = var.env
  }

depends_on = [
  aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
]

}



# NodeGroups
resource "aws_eks_node_group" "ondemand_node" {
   count          = var.is_eks_cluster_enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.eks[count.index].name
  node_group_name = "${var.cluster_name}-on-demand-nodes"
  node_role_arn   = aws_iam_role.eks_nodegroup_role[count.index].arn

  scaling_config {
    desired_size = var.desired_capacity_on_demand
    min_size     = var.min_capacity_on_demand
    max_size     = var.max_capacity_on_demand
  }

  subnet_ids = [aws_subnet.private1.id,aws_subnet.private2.id]

  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"
  labels = {
    type = "ondemand"
  }

  update_config {
    max_unavailable = 1
  }
  
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "Name" = "${var.cluster_name}-ondemand-nodes"
  }
depends_on = [
  aws_eks_cluster.eks,
  aws_iam_role_policy_attachment.eks_amazon_worker_node_policy,
  aws_iam_role_policy_attachment.eks_amazon_eks_cni_policy,
  aws_iam_role_policy_attachment.eks_ecr_readonly
]
}

