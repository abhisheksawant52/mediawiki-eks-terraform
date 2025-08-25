##############################################
# AWS / EKS Cluster
##############################################
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "test-cluster"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 1
}

##############################################
# VPC / Networking
##############################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "azs" {
  description = "Availability Zones for the public subnets"
  type        = list(string)
  default     = ["us-east-1a"]
}

##############################################
# MediaWiki / MariaDB
##############################################
variable "db_root_password" {
  type        = string
  description = "MariaDB root password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "mediawikidb"
}

variable "db_user" {
  type        = string
  description = "Database user"
  default     = "mediawikiuser"
}

variable "db_password" {
  type        = string
  description = "Database user password"
  sensitive   = true
}

variable "mediawiki_image" {
  type        = string
  description = "MediaWiki Docker image repository"
  default     = "aks-mediawiki/mediawiki"
}

variable "mediawiki_image_tag" {
  type        = string
  description = "MediaWiki Docker image tag"
  default     = "latest"
}

##############################################
# Jump Box / Bastion Host (Optional)
##############################################
variable "jump_ami" {
  description = "AMI ID for the jump box (Amazon Linux 2 recommended)"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "ssh_key_name" {
  description = "SSH key name to access the jump box"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation to allow SSH access (e.g., 203.0.113.25/32)"
  type        = string
}

variable "deploy_jump_box" {
  description = "Whether to deploy a jump box (true/false)"
  type        = bool
  default     = true
}
