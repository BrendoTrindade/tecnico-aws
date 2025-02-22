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
   - Projeto no GitHub: https://github.com/BrendoTrindade/tecnico-aws
   - Instruções de uso neste README
   - Código comentado para fácil entendimento

## 1. Infraestrutura AWS

Para criar a infraestrutura básica, usei Terraform por ser uma ferramenta popular e fácil de entender. A infraestrutura inclui:

1. O que será criado:
   - EC2: Servidor para rodar a aplicação (t2.micro - free tier)
   - RDS: Banco de dados MySQL (db.t3.micro - free tier)
   - S3: Armazenamento de arquivos
   - VPC: Rede isolada para os serviços

2. Medidas de Segurança:
   - EC2 acessível apenas via SSH com IP específico
   - HTTP permitido apenas da rede da empresa
   - RDS acessível apenas pela EC2
   - S3 com acesso restrito à aplicação

Aqui está o código comentado:

```hcl
# Configuração da região AWS
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
    cidr_blocks = ["${var.rede_empresa}"]  # Ex: "192.168.1.0/24"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 - Servidor da Aplicação
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"               # Free tier
  
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name = "app-server"
  }
}

# RDS - Banco de Dados MySQL
resource "aws_db_instance" "db" {
  engine               = "mysql"
  instance_class       = "db.t3.micro"     # Free tier
  allocated_storage    = 20
  skip_final_snapshot = true

  # Acesso apenas pela EC2
  vpc_security_group_ids = [aws_security_group.db.id]
}

# S3 - Armazenamento
resource "aws_s3_bucket" "files" {
  bucket = var.bucket_name

  tags = {
    Name = "app-files"
  }
}
```

Como aplicar:
1. Salvar as configurações em `main.tf`
2. Executar `terraform init` para baixar plugins
3. Executar `terraform apply` para criar infraestrutura

Benefícios desta configuração:
- Usa apenas recursos do free tier
- Segurança básica implementada
- Fácil de modificar e expandir
- Documentada para fácil entendimento

## 2. Infraestrutura como Código (IaC)

Escolhi Terraform como ferramenta IaC pelos seguintes motivos:
- Fácil de aprender e usar
- Boa documentação e comunidade ativa
- Integração nativa com AWS
- Permite ver as mudanças antes de aplicar

Processo de implementação:

1. Decisões de Configuração:
   - Application Load Balancer (ALB) por suportar HTTP/HTTPS
   - Duas EC2 em zonas diferentes para alta disponibilidade
   - Health check na porta 80 para garantir que aplicação está respondendo
   - Security groups permitindo apenas tráfego necessário

2. Estrutura do código:
   - Separei recursos em blocos lógicos
   - Usei count para criar múltiplas EC2s
   - Nomes descritivos para fácil identificação
   - Comentários explicando cada recurso

Configuração do Load Balancer:
```hcl
# Criar Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false                    # LB público
  load_balancer_type = "application"           # ALB para HTTP/HTTPS
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]  # Multi-AZ
}

# Target Group para as EC2
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80                    # Porta padrão HTTP
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path    = "/"                  # Verifica página inicial
    matcher = "200"                # Considera healthy se retornar HTTP 200
  }
}

# Anexar as EC2 ao Target Group
resource "aws_lb_target_group_attachment" "app" {
  count            = 2             # Criar duas EC2s
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

# Listener para o Load Balancer
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80           # Porta de entrada
  protocol          = "HTTP"

  default_action {
    type             = "forward"   # Encaminhar para target group
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
```

Para aplicar esta configuração:
1. Inicializar: `terraform init`
2. Validar: `terraform plan`
3. Aplicar: `terraform apply`

## 3. Continuidade de Negócio

Para garantir a continuidade dos serviços, implementei dois níveis de proteção:

A) Em caso de falha de uma Zona de Disponibilidade:
1. Multi-AZ na mesma região:
   - EC2 distribuídas em duas AZs (us-east-1a e us-east-1b)
   - RDS com Multi-AZ para failover automático
   - Load Balancer distribuindo tráfego entre AZs

2. Processo de failover AZ:
   - Load Balancer detecta falha e redireciona tráfego
   - RDS alterna automaticamente para a AZ secundária
   - Auto Scaling mantém número mínimo de EC2

B) Em caso de falha da região principal (us-east-1):
1. Backup em Região Secundária (us-west-2):
   - Replicação cross-region do RDS
   - Replicação do bucket S3
   - AMIs copiadas para região secundária

2. Configuração de Recuperação:
   - VPC e subnets já criadas na região secundária
   - Route53 com política de failover
   - Scripts de infraestrutura preparados para ambas regiões

3. Processo de Failover:
   - Route53 redireciona tráfego para região secundária
   - RDS promove réplica para master
   - EC2 é iniciada usando AMIs da região secundária

Com essa estrutura, estamos protegidos tanto contra falhas de AZ quanto de região.

## 4. Monitoramento e Logging

Para implementar o monitoramento da EC2 usando CloudWatch, seguirei estas etapas:

1. Primeiro, precisamos instalar o CloudWatch agent para coletar métricas:
```bash
# Instalação do agente
sudo yum install -y amazon-cloudwatch-agent
```

2. Configurar o agente para coletar as métricas básicas:
```json
{
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle"],
        "metrics_collection_interval": 300
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 300
      }
    }
  }
}
```

3. Para simular logs da aplicação:
```bash
# Criar diretório de logs
sudo mkdir -p /var/log/app

# Gerar alguns logs de exemplo
echo "[$(date)] INFO: Aplicação iniciada com sucesso" > /var/log/app/app.log
echo "[$(date)] INFO: Servidor web respondendo na porta 80" >> /var/log/app/app.log
```

4. Iniciar o monitoramento:
```bash
# Iniciar e habilitar o agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent
```

Com isso, teremos:
- Monitoramento de CPU e memória a cada 5 minutos
- Logs da aplicação sendo coletados
- Métricas disponíveis no dashboard do CloudWatch
- Possibilidade de criar alertas baseados nas métricas

## 5. Pipeline CI/CD

Criei um pipeline básico usando GitHub Actions para automatizar o deploy de uma aplicação. O pipeline faz:

1. **Quando é Executado:**
   - A cada push na branch main
   - Quando abre um Pull Request

2. **O Que o Pipeline Faz:**
   - Instala as dependências
   - Roda os testes básicos
   - Faz o deploy se estiver tudo ok

Exemplo do arquivo de pipeline (.github/workflows/main.yml):
```yaml
name: Pipeline Básico

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout do código
      uses: actions/checkout@v2

    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '14'

    - name: Instalar dependências
      run: npm install

    - name: Rodar testes
      run: npm test

    - name: Deploy para produção
      if: github.ref == 'refs/heads/main'
      run: |
        echo "Fazendo deploy..."
        # Aqui vai o comando de deploy
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