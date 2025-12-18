# 1. IAM Roles
# 2. ECS Cluster
# 3. Security Group for ECS backend
# 4. ECS Task Definition (backend)
#   4.1. ECS Service (backend)
#   4.2 Load balancer attachment (backend)
# 5. ECS Task Definition (frontend)
#   5.1. ECS Service (frontend)
#   5.2 Load balancer attachment (frontend)
# 7. Outputs


# 1. IAM Roles
# Task execution role  -> used by ECS agent for pull image from ECR, CloudWatch logs etc
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

# Task role  -> used by my app/container. Used for access to RDS, S3, Secret Manager etc
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

  cpu    = "256" 
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn  # used by ecs agent e.g. pull layers
  task_role_arn      = aws_iam_role.ecs_task_role.arn            # use by the app from container for auth to RDS for example

  container_definitions = jsonencode([                           # ECS API needs json => jsoncode
    {

      name  = "backend"
      image = "${var.ecr_repository_url}:latest" # ecr image -> latest

      essential = true # if this task crashed => ecs will see it as failed => restart

      portMappings = [
        {
          containerPort = var.container_port  # for awsvpc -> hostPort is the same as containerPort. So, if the app listens on port 5000, it should be 5000 here
          protocol      = "tcp"
        }
      ]

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

# 4.1. ECS Service (backend)
resource "aws_ecs_service" "backend" {
  name            = "${var.name}-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1 # number of tasks to run permanently

  launch_type = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
# 4.2 Load balancer attachment (backend)
  load_balancer {
    target_group_arn = var.backend_tg_arn
    container_name   = "backend"
    container_port   = var.container_port
  }

}

# 5. ECS Task Definition (frontend)
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "frontend"
      image = "${var.ecr_frontend_repository_url}:latest"

      portMappings = [
        {
          containerPort = 80
        }
      ]

      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.name}-frontend"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

#   5.1. ECS Service (frontend)
resource "aws_ecs_service" "frontend" {
  name            = "${var.name}-frontend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
# 5.2 Load balancer attachment (backend)
  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = "frontend"
    container_port   = 80
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.name}-backend"
  retention_in_days = 7 # delete logs after 7 days
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.name}-frontend"
  retention_in_days = 7 # delete logs after 7 days
}

