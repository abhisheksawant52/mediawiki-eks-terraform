output "cluster_endpoint" {
  value = aws_eks_cluster.abhishek.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.abhishek.certificate_authority[0].data
}

output "jump_box_public_ip" {
  value = aws_instance.abhishek_jump.public_ip
}
