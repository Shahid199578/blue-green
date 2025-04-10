output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.demo.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.demo.endpoint
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.demo.arn
}

output "kubeconfig" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.demo.name} --region ${var.region}"
}

output "private_key" {
  description = "Private key for SSH access"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "sonarqube_public_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "ssh_private_key_pem_file" {
  value = local_file.private_key_pem.filename
}


