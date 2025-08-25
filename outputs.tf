##############################################
# EKS Cluster Outputs
##############################################
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca" {
  description = "Base64 encoded certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

##############################################
# EKS Node Group Output
##############################################
output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.default.node_group_name
}

##############################################
# Kubernetes Namespace
##############################################
output "mediawiki_namespace" {
  description = "Kubernetes namespace for MediaWiki"
  value       = kubernetes_namespace.mediawiki.metadata[0].name
}

##############################################
# Helm Release Outputs (optional)
##############################################
output "mariadb_release_name" {
  description = "Helm release name for MariaDB"
  value       = helm_release.mariadb.name
}

output "mediawiki_release_name" {
  description = "Helm release name for MediaWiki"
  value       = helm_release.mediawiki.name
}

##############################################
# Instructions / Notes
##############################################
output "notes" {
  description = "Post-deployment instructions"
  value       = <<EOT
After terraform apply, run:
aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}
kubectl get svc -n ${kubernetes_namespace.mediawiki.metadata[0].name}
EOT
}


##############################################
# Jump Box (Optional)
##############################################
output "jump_box_public_ip" {
  description = "Public IP to SSH into the jump box (null if jump box not deployed)"
  value       = var.deploy_jump_box && length(aws_instance.jump_box) > 0 ? aws_instance.jump_box[0].public_ip : null
}
