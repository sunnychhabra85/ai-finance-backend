# ============================================
# Application Load Balancer (ALB)
# ============================================
# Cost: $22.32/month + $0.006 per LCU
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }
}

# ============================================
# ALB Listener - HTTP
# ============================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

# ============================================
# ALB Listener - HTTPS (OPTIONAL)
# ============================================
# Uncomment to enable HTTPS with SSL certificate
# You need an ACM certificate first:
# aws acm request-certificate --domain-name yourdomain.com --validation-method DNS

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = "arn:aws:acm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:certificate/YOUR_CERT_ID"
# 
#   default_action {
#     type = "fixed-response"
#
#     fixed_response {
#       content_type = "text/plain"
#       message_body = "OK"
#       status_code  = "200"
#     }
#   }
# }

# ============================================
# Target Groups for Each Service
# ============================================

# Auth Service Target Group
resource "aws_lb_target_group" "auth_service" {
  name_prefix = "auth"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-auth-tg-${var.environment}"
  }
}

# Upload Service Target Group
resource "aws_lb_target_group" "upload_service" {
  name_prefix = "upld"
  port        = 3002
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-upload-tg-${var.environment}"
  }
}

# Parser Worker Target Group
resource "aws_lb_target_group" "parser_worker" {
  name_prefix = "pars"
  port        = 3003
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-parser-tg-${var.environment}"
  }
}

# Analytics Service Target Group
resource "aws_lb_target_group" "analytics_service" {
  name_prefix = "anly"
  port        = 3004
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-analytics-tg-${var.environment}"
  }
}

# AI Service Target Group
resource "aws_lb_target_group" "ai_service" {
  name_prefix = "aism"
  port        = 3005
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-ai-tg-${var.environment}"
  }
}

# ============================================
# ALB Listener Rules - Route by Path
# ============================================

# /api/auth* → auth-service
resource "aws_lb_listener_rule" "auth_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/auth*"]
    }
  }
}

# /api/upload* → upload-service
resource "aws_lb_listener_rule" "upload_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.upload_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/upload*"]
    }
  }
}

# /api/parse* → parser-worker
resource "aws_lb_listener_rule" "parser_worker" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 3

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.parser_worker.arn
  }

  condition {
    path_pattern {
      values = ["/api/parse*"]
    }
  }
}

# /api/analytics* → analytics-service
resource "aws_lb_listener_rule" "analytics_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 4

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.analytics_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/analytics*"]
    }
  }
}

# /api/ai* → ai-service
resource "aws_lb_listener_rule" "ai_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/ai*"]
    }
  }
}