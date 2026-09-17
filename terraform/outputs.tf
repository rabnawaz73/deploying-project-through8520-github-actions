output "ecr_repository_url" {
  description = "ECR repository URL to push the app image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "alb_dns_name" {
  description = "Public URL for the application"
  value       = aws_lb.app.dns_name
}

output "ubuntu_instance_id" {
  description = "Ubuntu EC2 instance ID"
  value       = aws_instance.ubuntu.id
}

output "ubuntu_public_ip" {
  description = "Public IP address of the Ubuntu EC2 instance"
  value       = aws_instance.ubuntu.public_ip
}

output "terraform_state_bucket" {
  description = "S3 bucket created for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}
