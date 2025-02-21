# Teste Técnico DevOps

Este repositório contém as respostas do teste técnico DevOps, focando em infraestrutura AWS, IaC e boas práticas de documentação.

## Requisitos Atendidos

1. **AWS Free Tier:**
   - Todos os recursos dentro do nível gratuito
   - EC2: t2.micro
   - RDS: db.t3.micro
   - S3: dentro dos limites gratuitos

2. **Infraestrutura como Código:**
   - Terraform para criar e gerenciar recursos
   - Código organizado e comentado
   - Variáveis para configuração

3. **Documentação e GitHub:**
   - Código versionado neste repositório
   - README com instruções claras
   - Documentação dos recursos e decisões

## Como Usar

1. Clone o repositório:
```bash
git clone https://github.com/BrendoTrindade/tecnico-aws.git
cd tecnico-aws
```

2. Configure suas credenciais AWS:
```bash
aws configure
```

3. Inicie a infraestrutura:
```bash
cd terraform
terraform init
terraform apply
```

## Estrutura do Projeto

```
.
├── terraform/          # Código da infraestrutura
│   ├── main.tf        # Recursos AWS
│   ├── variables.tf   # Variáveis
│   └── outputs.tf     # Saídas
├── docs/              # Documentação
│   └── respostas.md   # Respostas do teste
└── README.md          # Este arquivo
```
