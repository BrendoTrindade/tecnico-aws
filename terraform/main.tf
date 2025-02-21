# Configuração da AWS
provider "aws" {
  region = "us-east-1"  # Região mais comum
}

# VPC para nossos recursos
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "vpc-principal"
  }
}

# Subnets em zonas diferentes
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = "us-east-1${count.index == 0 ? "a" : "b"}"
}

# EC2 para a aplicação
resource "aws_instance" "app" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"  # Free tier
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "app-server-${count.index + 1}"
  }
}

# RDS para o banco
resource "aws_db_instance" "database" {
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class      = "db.t3.micro"  # Free tier
  allocated_storage   = 20
  identifier          = "app-database"
  username           = "admin"
  password           = var.db_password
  multi_az           = true
  skip_final_snapshot = true
}

# S3 para arquivos
resource "aws_s3_bucket" "files" {
  bucket = "minha-app-arquivos"
}

# Load Balancer
resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets           = aws_subnet.public[*].id
}

# Target Group
resource "aws_lb_target_group" "app" {
  name     = "app-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
