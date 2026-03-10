terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.34.0 "
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "eks" {
  count = var.is_eks_cluster_enabled ? 1 : 0
  name  = aws_eks_cluster.eks[0].name
}

data "aws_eks_cluster_auth" "eks" {
  count = var.is_eks_cluster_enabled ? 1 : 0
  name  = aws_eks_cluster.eks[0].name
}

provider "kubernetes" {
  host                   = var.is_eks_cluster_enabled ? data.aws_eks_cluster.eks[0].endpoint : ""
  cluster_ca_certificate = var.is_eks_cluster_enabled ? base64decode(data.aws_eks_cluster.eks[0].certificate_authority[0].data) : ""
  token                  = var.is_eks_cluster_enabled ? data.aws_eks_cluster_auth.eks[0].token : ""
}

provider "helm" {
  kubernetes {
    host                   = var.is_eks_cluster_enabled ? data.aws_eks_cluster.eks[0].endpoint : ""
    cluster_ca_certificate = var.is_eks_cluster_enabled ? base64decode(data.aws_eks_cluster.eks[0].certificate_authority[0].data) : ""
    token                  = var.is_eks_cluster_enabled ? data.aws_eks_cluster_auth.eks[0].token : ""
  }
}
