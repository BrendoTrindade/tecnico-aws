# Configuração da AWS
provider "aws" {
  region = "us-east-1"  # Região mais comum e com todos os serviços
}

# VPC para nossos recursos
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "vpc-principal"
  }
}

# Subnets públicas em zonas diferentes
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = "us-east-1${count.index == 0 ? "a" : "b"}"
  
  tags = {
    Name = "subnet-publica-${count.index + 1}"
  }
}

# Servidores Web
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"  # Free tier
  subnet_id     = aws_subnet.public[count.index].id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              echo "<h1>Servidor ${count.index + 1}</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

# RDS MySQL
resource "aws_db_instance" "banco" {
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class      = "db.t3.micro"  # Free tier
  allocated_storage   = 20
  identifier          = "app-database"
  username           = "admin"
  password           = var.db_password
  multi_az           = true  # Para alta disponibilidade
  skip_final_snapshot = true

  backup_retention_period = 7  # 7 dias de backup
  backup_window          = "03:00-04:00"  # Backup às 3h

  tags = {
    Name = "banco-mysql"
  }
}

# S3 para arquivos
resource "aws_s3_bucket" "arquivos" {
  bucket = "meus-arquivos-app"

  versioning {
    enabled = true  # Mantém versões antigas
  }

  replication_configuration {
    role = aws_iam_role.replication.arn
    rules {
      id     = "backup-us-west-2"
      status = "Enabled"
      destination {
        bucket = aws_s3_bucket.backup.arn
        region = "us-west-2"
      }
    }
  }

  tags = {
    Name = "bucket-arquivos"
  }
}

# Load Balancer
resource "aws_lb" "balanceador" {
  name               = "meu-lb"
  internal           = false
  load_balancer_type = "application"
  subnets           = aws_subnet.public[*].id

  tags = {
    Name = "load-balancer"
  }
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "web-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Listener
resource "aws_lb_listener" "balanceador" {
  load_balancer_arn = aws_lb.balanceador.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# CloudWatch para monitoramento
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "cpu-alto"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU acima de 80%"

  dimensions = {
    InstanceId = aws_instance.web[0].id
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  desired_capacity    = 2
  max_size           = 4
  min_size           = 2
  target_group_arns  = [aws_lb_target_group.web.arn]
  vpc_zone_identifier = aws_subnet.public[*].id

  tag {
    key                 = "Name"
    value               = "web-server-asg"
    propagate_at_launch = true
  }
}
