# Configuração AWS
provider "aws" {
  region = "us-east-1"  # Região com menor latência para Brasil
}

# VPC para isolar os recursos
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # Rede privada
  
  tags = {
    Name = "app-vpc"
  }
}

# Security Group para EC2 - Controla acesso
resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id

  # Permite SSH apenas do meu IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.meu_ip}/32"]
  }

  # Permite HTTP apenas da rede da empresa
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.rede_empresa}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}

# Security Group - RDS
resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name = "db-sg"
  }
}

# EC2 - Servidor da Aplicação
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"               # Free tier
  
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name              = var.key_name

  tags = {
    Name = "app-server"
  }
}

# RDS - Banco de Dados MySQL
resource "aws_db_instance" "db" {
  engine               = "mysql"
  instance_class       = "db.t3.micro"     # Free tier
  allocated_storage    = 20
  username            = var.db_user
  password            = var.db_password
  skip_final_snapshot = true

  # Acesso apenas pela EC2
  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Name = "app-db"
  }
}

# S3 - Armazenamento
resource "aws_s3_bucket" "files" {
  bucket = var.bucket_name

  tags = {
    Name = "app-files"
  }
}
