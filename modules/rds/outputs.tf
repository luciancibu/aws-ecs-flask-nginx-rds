# 4. Outputs
#   4.1 Endpoint
#   4.2 Port

output "endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "port" {
  value = aws_db_instance.mysql.port
}

output "security_group_id" {
  value = aws_security_group.rds_sg.id
}
