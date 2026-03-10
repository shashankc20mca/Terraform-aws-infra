############################################
# EBS CSI Driver Addon (IRSA) - FINAL
############################################

locals {
  eks_enabled = var.is_eks_cluster_enabled == true
}

data "tls_certificate" "eks_oidc" {
  count = local.eks_enabled ? 1 : 0
  url   = aws_eks_cluster.eks[count.index].identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.eks]
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = local.eks_enabled ? 1 : 0

  url             = aws_eks_cluster.eks[count.index].identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc[count.index].certificates[0].sha1_fingerprint]

  depends_on = [aws_eks_cluster.eks]
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = local.eks_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks[count.index].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.eks[count.index].identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.eks[count.index].identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_irsa" {
  count = local.eks_enabled ? 1 : 0

  name               = "${var.cluster_name}-ebs-csi-irsa"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_irsa_policy" {
  count = local.eks_enabled ? 1 : 0

  role       = aws_iam_role.ebs_csi_irsa[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  count = local.eks_enabled ? 1 : 0

  cluster_name             = aws_eks_cluster.eks[count.index].name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_irsa[count.index].arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.eks,
    aws_eks_node_group.ondemand_node,
    aws_iam_openid_connect_provider.eks[0], # must be constant inside depends_on block no [count.index] allowed
    aws_iam_role_policy_attachment.ebs_csi_irsa_policy
  ]
}
