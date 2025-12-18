# 1. IAM Roles
#   1.1 Task execution role
#   1.2 Task role

# 2. ECS Cluster

# 3. Security Group for ECS backend
#   3.1 Ingress: from ALB
#   3.2 Egress: allow all

# 4. ECS Task Definition (backend)
#   4.1 Container image (ECR)
#   4.2 CPU / Memory
#   4.3 Environment variables
#   4.4 Port mappings
#   4.5 Log configuration (CloudWatch)

# 5. ECS Service (backend)
#   5.1 Launch type: Fargate
#   5.2 Network configuration (private subnets)
#   5.3 Security groups
#   5.4 Desired count
#   5.5 Load balancer attachment (to be added later)

# 6. Outputs
#   6.1 Backend security group ID
#   6.2 Service name
#   6.3 Cluster name


# 1. IAM Roles
#   1.1 Task execution role  -> used by ECS agent for pull image from ECR, CloudWatch logs etc
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#   1.2 Task role  -> used by my app/container. Used for access to RDS, S3, Secret Manager etc
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-ecs-cluster"
}

# 3. Security Group for ECS backend
resource "aws_security_group" "ecs_sg" {
  name   = "${var.name}-sg"
  vpc_id = var.vpc_id
}
#   3.1 Ingress: from ALB
# /end/dev/main.tf --> cycle error

#   3.2 Egress: allow all
resource "aws_security_group_rule" "ecs_egress" {
  security_group_id = aws_security_group.ecs_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# 4. ECS Task Definition (backend)
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name}-backend"
  network_mode             = "awsvpc"       # each task will have ENI in subnet (private IP from subnet) -> SG will be attached to ENI task
  requires_compatibilities = ["FARGATE"]    # serverless runtime

#   4.2 CPU / Memory
  cpu    = "256" 
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn  # used by ecs agent e.g. pull layers
  task_role_arn      = aws_iam_role.ecs_task_role.arn            # use by the app from container for auth to RDS for example

  container_definitions = jsonencode([                           # ECS API needs json => jsoncode
    {

#   4.1 Container image (ECR)
      name  = "backend"
      image = "${var.ecr_repository_url}:latest" # ecr image -> latest

      essential = true # if this task crashed => ecs will see it as failed => restart

#   4.4 Port mappings
      portMappings = [
        {
          containerPort = var.container_port  # for awsvpc -> hostPort is the same as containerPort. So, if the app listens on port 5000, it should be 5000 here
          protocol      = "tcp"
        }
      ]

#   4.3 Environment variables
      # ECS injects these variables into the container when it starts
      environment = [   
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_USER"
          value = var.db_user
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        }
      ]
#   4.5 Log configuration (CloudWatch)
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.name}-backend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# 5. ECS Service (backend)
resource "aws_ecs_service" "backend" {
  name            = "${var.name}-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
#   5.4 Desired count
  desired_count   = 1 # number of tasks to run permanently

#   5.1 Launch type: Fargate
  launch_type = "FARGATE"

#   5.2 Network configuration
#   5.3 Security groups
  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}

#   5.5 Load balancer attachment (to be added later) -> to be added
