##############################################
# AWS Provider
##############################################
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

##############################################
# Kubernetes Provider (for EKS)
##############################################
provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.this.name,
      "--region",
      var.region
    ]
  }
}

##############################################
# Helm Provider (uses the same kubeconfig as Kubernetes provider)
##############################################
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.this.name,
        "--region",
        var.region
      ]
    }
  }
}
