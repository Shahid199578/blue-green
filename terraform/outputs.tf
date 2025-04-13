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

