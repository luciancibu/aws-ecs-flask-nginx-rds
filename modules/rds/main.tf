# 1. DB subnet group (private subnets only)
# 2. Security group for RDS
#   2.1 Ingress: DB port
#   2.2 Egress: all
# 3. RDS MySQL instance
#   3.1 Engine + instance class
#   3.2 Network (subnet group + SG)
#   3.3 Credentials
# 4. Outputs
#   4.1 Endpoint
#   4.2 Port

# 1. DB subnet group (private subnets only)
resource "aws_db_subnet_group" "this" {
  name       = "rds-private-subnets"
  subnet_ids = var.private_subnets

  tags = {
    Name = "rds-private-subnets"
  }
}

# 2. Security group for RDS
resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = var.vpc_id
}

# 2.1 Ingress: DB port (from ECS backend)
resource "aws_security_group_rule" "rds_ingress" {
  count = var.allowed_sg_id == null ? 0 : 1

  security_group_id        = aws_security_group.rds_sg.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.allowed_sg_id
}

# 2.2 Egress: all
resource "aws_security_group_rule" "rds_egress" {
  security_group_id = aws_security_group.rds_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# 3. RDS MySQL instance
#   3.1 Engine + instance class
#   3.2 Network (subnet group + SG)
#   3.3 Credentials
resource "aws_db_instance" "mysql" {
  identifier = "backend-mysql"
  allocated_storage    = 10
  db_name              = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.username
  password             = var.password
  skip_final_snapshot  = var.skip_final_snapshot
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

}
