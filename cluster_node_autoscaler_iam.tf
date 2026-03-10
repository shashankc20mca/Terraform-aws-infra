# OIDC provider that is tls_certificate and aws_iam_openid_connect_provider already created for ebs.tf 
# that will be reused by service account to implent irsa(IAM Roles for Service Accounts) in eks
# In Kubernetes, a Service Account is an identity for applications (pods) running inside the cluster.
# Human user ----> IAM user / kubectl user
# pod ------> service account

# IAM policy
resource "aws_iam_policy" "cluster_autoscaler" {
  count = local.eks_enabled ? 1 : 0

  name = "${var.cluster_name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      }
    ]
  })
}
# IAM role for the Kubernetes service account
data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
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
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler_irsa" {
  count = local.eks_enabled ? 1 : 0

  name               = "${var.cluster_name}-cluster-autoscaler-irsa"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role[count.index].json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_irsa_policy" {
  count = local.eks_enabled ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler_irsa[count.index].name
  policy_arn = aws_iam_policy.cluster_autoscaler[count.index].arn
}

