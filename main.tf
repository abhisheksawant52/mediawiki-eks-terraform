##############################################
# VPC (Minimal)
##############################################
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "Mindhacker-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "Mindhacker-igw" }
}

resource "aws_subnet" "public_1" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.this.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "Mindhacker-public-1" }
}

resource "aws_subnet" "public_2" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.this.id
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "Mindhacker-public-2" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "Mindhacker-public-rt" }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

##############################################
# IAM Roles for EKS
##############################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "Abhishek-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "Abhishek-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

##############################################
# EKS Cluster (Minimal)
##############################################
resource "aws_eks_cluster" "this" {
  name     = "Abhishek-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

##############################################
# EKS Node Group (1 small node)
##############################################
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "Abhishek-default"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_1.id] # Nodes in one subnet

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.micro"]

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy
  ]
}

##############################################
# Kubernetes namespace
##############################################
resource "kubernetes_namespace" "mediawiki" {
  metadata {
    name = "mindhacker-mediawiki"
  }
}

##############################################
# Helm: MariaDB (minimal)
##############################################
resource "helm_release" "mariadb" {
  name      = "mindhacker-database"
  namespace = kubernetes_namespace.mediawiki.metadata[0].name
  chart     = "./mediawiki-mariadb-chart"
  values    = [file("${path.module}/values-mediawiki-mariadb.yaml")]

  depends_on = [aws_eks_node_group.default]
}

##############################################
# Helm: MediaWiki
##############################################
resource "helm_release" "mediawiki" {
  name      = "mindhacker-mediawiki"
  namespace = kubernetes_namespace.mediawiki.metadata[0].name
  chart     = "./mediawiki-chart"
  values    = [file("${path.module}/values-mediawiki.yaml")]

  depends_on = [helm_release.mariadb]
}

##############################################
# Jump Box / Bastion Host (Optional)
##############################################
resource "aws_security_group" "jump_sg" {
  count       = var.deploy_jump_box ? 1 : 0
  name        = "mindhacker-jump-sg"
  description = "Security group for the jump box"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]  # your public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mindhacker-jump-sg" }
}

resource "aws_instance" "jump_box" {
  count                  = var.deploy_jump_box ? 1 : 0
  ami                    = var.jump_ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.jump_sg[0].id]
  key_name               = var.ssh_key_name

  tags = {
    Name = "mindhacker-jump"
  }
}
