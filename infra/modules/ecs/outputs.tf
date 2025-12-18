output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "service_name" {
  value = aws_ecs_service.backend.name
}