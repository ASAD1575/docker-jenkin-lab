output "ecr_repo_url" {
    value = aws_ecr_repository.jenkins-pipeline.repository_url
  
}

output "ecs_service_name" {
    value = aws_ecs_service.node-app-service.name
  
}

output "ecs_cluster_name" {
    value = aws_ecs_cluster.node-app-cluster.name
  
}

output "ecs_service_url" {
  description = "Public URL to access ECS service"
  value       = aws_lb.ecs_alb.dns_name
}


