# Região AWS
variable "aws_region" {
  description = "Região AWS a ser utilizada"
  type        = string
  default     = "us-east-1"
}

# IP para acesso SSH
variable "ip_acesso" {
  description = "IP permitido para acesso SSH"
  type        = string
}

# Chave SSH
variable "key_name" {
  description = "Nome da chave SSH para acesso à EC2"
  type        = string
}

# Configurações RDS
variable "db_user" {
  description = "Usuário do banco de dados RDS"
  type        = string
}

variable "db_password" {
  description = "Senha do banco de dados RDS"
  type        = string
  sensitive   = true
}

# Nome do bucket S3
variable "bucket_name" {
  description = "Nome do bucket S3 para armazenamento"
  type        = string
}
