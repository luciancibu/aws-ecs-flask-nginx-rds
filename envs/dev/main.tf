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
}
