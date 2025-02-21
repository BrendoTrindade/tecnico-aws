# Respostas - Teste Técnico DevOps

Este projeto atende aos requisitos solicitados:

1. **Infraestrutura AWS (Free Tier):**
   - Uso apenas instâncias t2.micro para EC2
   - RDS com db.t3.micro
   - Bucket S3 dentro do limite gratuito
   - Outros serviços dentro da camada gratuita

2. **Configurações IaC:**
   - Uso Terraform para criar toda infraestrutura
   - Código está na pasta `/terraform`
   - Documentei cada recurso criado

3. **Documentação e GitHub:**
   - Projeto no GitHub: [https://github.com/BrendoTrindade/tecinico-aws](https://github.com/BrendoTrindade/tecnico-aws)
   - Instruções de uso neste README
   - Código comentado para fácil entendimento

## 1. Infraestrutura AWS

Para criar a infraestrutura básica, usei Terraform porque é mais fácil de entender e tem bastante material de estudo:

```hcl
# Criar EC2
resource "aws_instance" "servidor" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"  # Free tier
  
  tags = {
    Name = "Meu-Servidor"
  }
}

# Criar RDS
resource "aws_db_instance" "banco" {
  engine            = "mysql"
  instance_class    = "db.t3.micro"  # Free tier
  allocated_storage = 20
  username         = "admin"
  password         = "Senha123!"  # Depois mudo para variável
}

# Criar S3
resource "aws_s3_bucket" "arquivos" {
  bucket = "meus-arquivos-app"
}
```

## 2. Load Balancer

Criei um load balancer para distribuir o tráfego entre duas EC2:

```hcl
# Criar duas EC2
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              echo "<h1>Servidor ${count.index + 1}</h1>" > /var/www/html/index.html
              EOF
}

# Criar Load Balancer
resource "aws_lb" "balanceador" {
  name               = "meu-lb"
  internal           = false
  load_balancer_type = "application"
  subnets           = [aws_subnet.public[0].id, aws_subnet.public[1].id]
}
```

## 3. Continuidade de Negócio

Para manter tudo funcionando se der problema:

1. No RDS:
   - Ativei Multi-AZ
   - Backup automático todo dia às 3h
   - Guardo 7 dias de backup

2. Nas EC2:
   - Uma em us-east-1a e outra em us-east-1b
   - Auto Scaling com mínimo de 2 instâncias
   - Backup semanal das AMIs

3. No S3:
   - Ativei versionamento
   - Replicação para us-west-2
   - Backup dos arquivos importantes

## 4. Monitoramento

Configurei o CloudWatch nas EC2:

```json
{
  "metrics": {
    "cpu": {
      "measurement": ["usage"],
      "collect_interval": 300
    },
    "memory": {
      "measurement": ["used", "free"],
      "collect_interval": 300
    }
  },
  "logs": {
    "files": {
      "collect_list": [
        {
          "file_path": "/var/log/httpd/access_log",
          "log_group_name": "apache-logs"
        }
      ]
    }
  }
}
```

Criei alertas para:
- CPU acima de 80%
- Memória acima de 90%
- Erros no Apache

## 5. Pipeline CI/CD

Fiz um pipeline com GitHub Actions:

```yaml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node
        uses: actions/setup-node@v2
        with:
          node-version: '16'
      
      - name: Instalar e Testar
        run: |
          npm install
          npm test
      
      - name: Build
        run: |
          npm run build
          zip -r app.zip dist/

      - name: Deploy
        run: |
          aws s3 cp app.zip s3://meu-bucket/
          aws elasticbeanstalk create-application-version \
            --application-name minha-app \
            --version-label ${{ github.sha }}
```

## 6. Segurança no S3

Para garantir a segurança dos dados no S3, implementaria:

1. **Bloqueio de Acesso Público:**
   - Habilitar "Block Public Access"
   - Negar acesso não autenticado
   - Forçar uso de HTTPS

2. **Controle de Acesso:**
   - Criar grupos (devops, dev, prod)
   - Usar política de menor privilégio
   - Exemplo de política básica:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:GetObject",
                   "s3:ListBucket"
               ],
               "Resource": [
                   "arn:aws:s3:::meu-bucket/*"
               ]
           }
       ]
   }
   ```

3. **Segurança Adicional:**
   - Ativar criptografia
   - Habilitar logs de acesso
   - Usar VPC Endpoints

## 7. Otimização de Performance

Para otimizar a performance de uma aplicação web com milhares de acessos simultâneos, podemos configurar:

1. **Sistema de Cache:**
   - Implementar Redis como cache distribuído
   - Configurar clusters do Redis para alta disponibilidade
   - Definir políticas de cache para diferentes tipos de dados

2. **Armazenamento Estático:**
   - Utilizar Amazon S3 para armazenamento
   - Configurar CloudFront como CDN
   - Implementar políticas de lifecycle no S3

3. **Infraestrutura de Distribuição:**
   - Configurar Load Balancer (ELB)
   - Implementar Auto Scaling Groups
   - Distribuir em múltiplas Availability Zones

4. **Banco de Dados:**
   - Configurar Read Replicas para leitura
   - Implementar cache no nível do banco
   - Utilizar RDS Multi-AZ para alta disponibilidade

Estas configurações permitem:
- Alta disponibilidade
- Melhor distribuição de carga
- Escalabilidade automática
- Recuperação rápida de dados

## 8. Resolução de Problemas

Para resolver uma falha intermitente no serviço, eu seguiria estes passos:

1. Primeiro, olharia os logs no CloudWatch:
   - Verificaria os logs de erro do aplicativo
   - Usaria filtros para encontrar mensagens de erro
   - Observaria os horários que o problema acontece
   - Procuraria padrões nos logs (tipo "connection timeout" ou "memory exceeded")

2. Depois, checaria as métricas do CloudWatch:
   - Gráficos de CPU e memória
   - Número de requisições por minuto
   - Tempo de resposta do banco de dados
   - Uso de disco e rede

3. Se for problema de recurso:
   - Aumentaria a memória ou CPU da instância
   - Ajustaria o número máximo de conexões
   - Verificaria se precisa de mais espaço em disco

4. Se for problema de código:
   - Adicionaria mais logs para entender melhor
   - Verificaria as últimas alterações feitas
   - Testaria reverter para a versão anterior

5. Para monitorar a solução:
   - Criaria alertas no CloudWatch para avisar se o problema voltar
   - Manteria os logs por mais tempo para análise
   - Documentaria o que foi feito para resolver

## 9. Lambda vs EC2

EC2 é como um servidor virtual na AWS. É bom para cenários como:
- Sites e aplicações que precisam ficar online 24 horas
- Sistemas grandes que muitas pessoas usam ao mesmo tempo
- Aplicações que precisam de muita memória ou processamento
- Bancos de dados e sistemas que guardam muitas informações

Lambda é uma função que roda só quando precisamos. Funciona bem em cenários como:
- Processar imagens quando alguém faz upload
- Fazer backups automáticos
- Enviar emails quando acontece algo no sistema
- Gerar relatórios periodicamente
- Integrar com outros serviços da AWS

A principal diferença é que o EC2 fica sempre ligado, enquanto o Lambda só roda quando precisa, o que pode ser mais econômico para algumas tarefas.

## 10. Automação

No meu trabalho com pipeline CI/CD, percebi várias tarefas que podemos automatizar para ajudar o time:

1. Testes do código:
   - Rodar testes automáticos
   - Verificar se o código está bem escrito
   - Procurar erros comuns
   - Ver se tem algum problema de segurança

2. Preparar o código para deploy:
   - Instalar as bibliotecas necessárias
   - Gerar os arquivos finais
   - Criar a versão para colocar em produção
   - Fazer backup antes de atualizar

3. Avisar o time:
   - Mandar mensagem quando começa o deploy
   - Avisar se deu algum erro
   - Informar quando terminou
   - Mostrar o que mudou

4. Verificar se está tudo certo:
   - Testar se a aplicação subiu
   - Ver se as páginas estão abrindo
   - Checar se o banco está funcionando
   - Voltar versão anterior se der problema

Isso ajuda muito o time porque:

1. Evita Erros:
   - Não esquecemos nenhum passo
   - Todo deploy é feito do mesmo jeito
   - Menos chance de erro humano

2. Economiza Tempo:
   - Não precisamos fazer tudo manual
   - Deploy mais rápido
   - Podemos fazer outras coisas enquanto roda

3. Fica Mais Seguro:
   - Sempre roda todos os testes
   - Faz backup antes
   - Avisa se der problema

4. Mais Fácil de Acompanhar:
   - Todo mundo sabe o que está acontecendo
   - Dá pra ver o histórico de deploys
   - Mais fácil de encontrar problemas

## 11. Experiência Profissional

Na minha última experiência, trabalhei em um projeto onde precisei migrar uma aplicação PHP para containers Docker. Foi um desafio interessante porque:

1. Desafios que enfrentei:
   - Aprender a usar Docker
   - Configurar o ambiente de desenvolvimento
   - Fazer o deploy em produção

2. Como resolvi:
   - Estudei a documentação do Docker
   - Fiz vários testes em ambiente de desenvolvimento
   - Usei Docker Compose para facilitar

3. Resultados:
   - Deploy mais rápido
   - Ambiente mais consistente
   - Menos problemas de configuração

Foi uma experiência muito boa porque aprendi bastante sobre containers e como usar em produção.