# Availability zones
data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "abhishek_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "Abhishek-VPC" }
}

# Public subnets
resource "aws_subnet" "abhishek_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.abhishek_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.abhishek_vpc.cidr_block, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "Abhishek-Subnet-${count.index}" }
}

# Internet Gateway
resource "aws_internet_gateway" "abhishek_igw" {
  vpc_id = aws_vpc.abhishek_vpc.id
  tags   = { Name = "Abhishek-IGW" }
}

# Route Table
resource "aws_route_table" "abhishek_route" {
  vpc_id = aws_vpc.abhishek_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.abhishek_igw.id
  }

  tags = { Name = "Abhishek-Route" }
}

# Route Table Associations
resource "aws_route_table_association" "abhishek_rta" {
  count          = 2
  subnet_id      = aws_subnet.abhishek_subnets[count.index].id
  route_table_id = aws_route_table.abhishek_route.id
}

# IAM Roles for EKS Cluster and Node Group
resource "aws_iam_role" "eks_cluster_role" {
  name = "Abhishek-EKS-Cluster-Role"

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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "Abhishek-EKS-Node-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "abhishek" {
  name     = "Abhishek-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = aws_subnet.abhishek_subnets[*].id
  }

  tags = { Name = "Abhishek" }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy, aws_iam_role_policy_attachment.eks_vpc_controller]
}

# EKS Node Group
resource "aws_eks_node_group" "abhishek_nodes" {
  cluster_name    = aws_eks_cluster.abhishek.name
  node_group_name = "Abhishek-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.abhishek_subnets[*].id

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_capacity
    max_size     = var.node_max_capacity
  }

  instance_types = [var.node_instance_type]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
  }

  tags = { Name = "Abhishek" }

  depends_on = [aws_eks_cluster.abhishek]
}

# Security group for Jump Box
resource "aws_security_group" "abhishek_jump" {
  name        = "Abhishek-jump-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.abhishek_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jump Box EC2 with kubectl, Helm, Docker, and Abhishek user
resource "aws_instance" "abhishek_jump" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.micro"
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.abhishek_subnets[0].id
  security_groups        = [aws_security_group.abhishek_jump.id]
  associate_public_ip_address = true

  tags = { Name = "Abhishek-JumpBox" }

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras enable docker
yum install -y docker git unzip curl jq sudo
systemctl enable docker
systemctl start docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create user Abhishek
useradd Abhishek
echo "Abhishek:Abhishek" | chpasswd
usermod -aG wheel Abhishek

# Setup kubeconfig for ec2-user
mkdir -p /home/ec2-user/.kube
aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.abhishek.name} --kubeconfig /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config
chmod 600 /home/ec2-user/.kube/config

# Setup kubeconfig for Abhishek user
mkdir -p /home/Abhishek/.kube
aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.abhishek.name} --kubeconfig /home/Abhishek/.kube/config
chown Abhishek:Abhishek /home/Abhishek/.kube/config
chmod 600 /home/Abhishek/.kube/config
EOF
}
