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
  name       = "${var.name}-subnets-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.name}-subnets-group"
  }
}

# 2. Security group for RDS
resource "aws_security_group" "rds_sg" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id
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
  identifier = "${var.name}-database"
  allocated_storage    = var.allocated_storage
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
