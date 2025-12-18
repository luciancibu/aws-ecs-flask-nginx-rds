# 1. Security group for ALB
# 2. Application Load Balancer
# 3. Target groups
#   3.1 Frontend target group
#   3.2 Backend target group
# 4. Listener

# 5. Listener rules
#   5.1 Path-based routing
#       - "/view/*"  → backend target group
#       - "/"        → frontend target group (implicit via default)

# 6. Outputs
#   6.1 ALB DNS name
#   6.2 ALB security group ID
#   6.3 Frontend target group ARN
#   6.4 Backend target group ARN


# 1. Security group for ALB
resource "aws_security_group" "alb_sg" {
  name   = "${var.name}-alb-sg"
  description = "Allow HTTP/HTTPS from Internet"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "http_from_public" {
  security_group_id        = aws_security_group.alb_sg.id

  description              = "HTTP from public"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_to_frontend" {
  security_group_id        = aws_security_group.alb_sg.id
  
  description              = "Outbound to everywhere"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
}

# 2. Application Load Balancer
resource "aws_lb" "frontend_alb" {
  name               = "${var.name}-alb"
  load_balancer_type = "application" 
  internal           = false # -> public alb

  security_groups = [
    aws_security_group.alb_sg.id
  ]

  subnets = var.public_subnets

  tags = {
    Name = "${var.name}-alb"
  }
}


# 3. Target groups
#   3.1 Frontend target group
resource "aws_lb_target_group" "frontend_tg" {
  name     = "${var.name}-frontend-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id  = var.vpc_id

  health_check {
    path                = "/"
  }

  tags = {
    Name = "${var.name}-frontend-tg"
  }
}
#   3.2 Backend target group
resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.name}-backend-tg"
  port     = 5000
  protocol = "HTTP"
  target_type = "ip"
  vpc_id  = var.vpc_id

  health_check {
    path                = "/"
  }
  tags = {
    Name = "${var.name}-backend-tg"
  }
}
# 4. Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# 5. Listener rules 
# "/view/*"  → backend target group ---> if not => "/" (default)
resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/view/*"]
    }
  }
}
