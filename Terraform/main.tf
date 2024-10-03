provider "aws" {
  region = var.aws_region
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "medusa-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id
  description = "Allow inbound traffic for ECS services"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  description = "Allow RDS connections from ECS"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "medusa_ecs_cluster" {
  name = "medusa-ecs-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the ECS Task Execution Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS-managed policy for RDS access to the ECS Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_rds_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# Attach ECR read-only access policy to the ECS Task Role
resource "aws_iam_role_policy_attachment" "ecs_task_ecr_readonly_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "medusa_task" {
  family                = "medusa-task"
  network_mode          = "awsvpc"
  cpu                   = 512
  memory                = 1024
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn         = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<DEFINITION
[
  {
    "name": "medusa-container",
    "image": "982534366726.dkr.ecr.ap-south-1.amazonaws.com/medusa-backend-1:latest",
    "essential": true,
    "memory": 1024,
    "cpu": 512,
    "portMappings": [
      {
        "containerPort": 9000,
        "hostPort": 9000,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "DATABASE_URL",
        "value": "postgres://medusa_user:${var.db_password}@${aws_db_instance.medusa_db.endpoint}:5432/medusadb"
      }
    ]
  }
]
DEFINITION
}

# ECS Service with Fargate Spot (No Load Balancer)
resource "aws_ecs_service" "medusa_service" {
  name            = "medusa-service"
  cluster         = aws_ecs_cluster.medusa_ecs_cluster.id
  task_definition = aws_ecs_task_definition.medusa_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  platform_version = "LATEST"
}
resource "aws_appautoscaling_target" "ecs_service_target" {
  max_capacity       = 3  # Set your maximum capacity
  min_capacity       = 1  # Set your minimum capacity
  resource_id        = "service/${aws_ecs_cluster.medusa_ecs_cluster.name}/${aws_ecs_service.medusa_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy
resource "aws_appautoscaling_policy" "scale_out" {
  name                   = "scale-out"
  policy_type           = "TargetTrackingScaling"
  resource_id           = aws_appautoscaling_target.ecs_service_target.id
  scalable_dimension     = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace      = aws_appautoscaling_target.ecs_service_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 75.0  # Target CPU utilization
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_out_cooldown   = 60
    scale_in_cooldown    = 60
  }
}

# CloudWatch Alarm for Scale Out
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "HighCPUAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "MemoryUtilization"
  namespace          = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = "75" # Trigger when CPU utilization exceeds 75%
  alarm_description   = "Alarm when CPU exceeds 75%"
  dimensions = {
    ClusterName = aws_ecs_cluster.medusa_ecs_cluster.name
    ServiceName = aws_ecs_service.medusa_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
}

# Scale In Policy
resource "aws_appautoscaling_policy" "scale_in" {
  name                   = "scale-in"
  policy_type           = "TargetTrackingScaling"
  resource_id           = aws_appautoscaling_target.ecs_service_target.id
  scalable_dimension     = aws_appautoscaling_target.ecs_service_target.scalable_dimension
  service_namespace      = aws_appautoscaling_target.ecs_service_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 25.0  # Target CPU utilization
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_out_cooldown   = 60
    scale_in_cooldown    = 60
  }
}

# CloudWatch Alarm for Scale In
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "LowCPUAlarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "60"
  statistic          = "Average"
  threshold          = "25" # Trigger when CPU utilization falls below 25%
  alarm_description   = "Alarm when CPU falls below 25%"
  dimensions = {
    ClusterName = aws_ecs_cluster.medusa_ecs_cluster.name
    ServiceName = aws_ecs_service.medusa_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "medusa_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = "db.t3.micro"
  db_name              = "medusadb"
  username             = "medusa_user"
  password             = var.db_password
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "medusa-db-subnet-group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}
