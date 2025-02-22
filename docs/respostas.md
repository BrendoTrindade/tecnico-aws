# Respostas Técnicas

## 1. Infraestrutura AWS

Implementei uma infraestrutura básica usando Terraform com recursos do nível gratuito:
- EC2 t2.micro para a aplicação
- RDS MySQL db.t3.micro para banco de dados
- S3 para armazenamento

```hcl
# Configuração AWS
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "app-vpc"
  }
}

# Security Group - EC2
resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ip_acesso}/32"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# EC2
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name              = var.key_name

  tags = {
    Name = "app-server"
  }
}

# RDS
resource "aws_db_instance" "db" {
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  username            = var.db_user
  password            = var.db_password
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Name = "app-db"
  }
}

# S3
resource "aws_s3_bucket" "files" {
  bucket = var.bucket_name

  tags = {
    Name = "app-files"
  }
}
```

Segurança implementada:
- SSH liberado apenas para IP específico
- Banco de dados acessível somente pela EC2
- Security groups para controle de acesso