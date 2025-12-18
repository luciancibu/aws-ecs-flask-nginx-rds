# Cyclic dependency: each group will be created in its specific module,
# but the security rules between them will be defined here


resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  security_group_id        = module.rds.rds_sg_id

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.ecs.ecs_sg_id
}

resource "aws_security_group_rule" "ecs_ingress" {
  security_group_id        = module.ecs.ecs_sg_id

  description              = "Access from ALB-sg"
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  source_security_group_id = module.alb.alb_sg_id
}

#  ECR
resource "aws_ecr_repository" "backend" {
  name = "backend-flask"
}

module "vpc" {
  source = "../../modules/vpc"

  name = "dev-vpc"
  cidr = "10.0.0.0/16"

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  azs = [
    "us-east-1a",
    "us-east-1b"
  ]
}

module "rds" {
  source = "../../modules/rds"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  username = "bbbb"
  password = "SuperPass123"
  name ="rds"
}

module "ecs" {
  source = "../../modules/ecs"

  name               = "dev-backend"
  vpc_id             = module.vpc.vpc_id
  aws_region         = var.aws_region
  ecr_repository_url = aws_ecr_repository.backend.repository_url


  db_host     = module.rds.endpoint
  db_user     = module.rds.username
  db_password = module.rds.password
  db_name     = module.rds.db_name
  private_subnets = module.vpc.private_subnets
}

module "alb" {
  source = "../../modules/alb"

  name               = "dev-ALB"
  vpc_id             = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets

}


