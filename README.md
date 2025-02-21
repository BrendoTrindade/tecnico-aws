# Teste Técnico DevOps

Este repositório contém a implementação de uma infraestrutura AWS usando Terraform, seguindo as melhores práticas de DevOps.

## Requisitos Atendidos

1. **AWS Free Tier:**
   - EC2: t2.micro para servidores web
   - RDS: db.t3.micro para MySQL
   - S3: armazenamento dentro do limite gratuito
   - Outros serviços mantidos no free tier

2. **Infraestrutura como Código:**
   - Terraform para toda a infraestrutura
   - Código organizado e documentado
   - Recursos modulares e reutilizáveis

3. **Documentação e GitHub:**
   - Código versionado neste repositório
   - Documentação detalhada
   - Exemplos práticos de uso

## Como Usar

1. Clone o repositório:
```bash
git clone https://github.com/BrendoTrindade/tecinico-aws.git
cd tecinico-aws
```

2. Configure suas credenciais AWS:
```bash
aws configure
```

3. Inicialize o Terraform:
```bash
cd terraform
terraform init
```

4. Revise as mudanças:
```bash
terraform plan
```

5. Aplique a infraestrutura:
```bash
terraform apply
```

## Estrutura do Projeto

```
.
├── terraform/
│   ├── main.tf          # Recursos principais
│   ├── variables.tf     # Variáveis
│   └── outputs.tf       # Saídas
├── docs/
│   └── respostas.md     # Respostas detalhadas
└── README.md            # Este arquivo
```

## Recursos Criados

1. **Rede:**
   - VPC dedicada
   - Subnets em duas AZs
   - Internet Gateway

2. **Computação:**
   - 2 EC2 t2.micro
   - Load Balancer
   - Auto Scaling Group

3. **Banco de Dados:**
   - RDS MySQL
   - Multi-AZ para alta disponibilidade
   - Backups automáticos

4. **Armazenamento:**
   - Bucket S3
   - Versionamento
   - Replicação para DR

5. **Monitoramento:**
   - CloudWatch Alarms
   - Métricas de CPU/Memória
   - Logs da aplicação

## Segurança

- Acesso restrito por Security Groups
- Banco de dados em subnet privada
- S3 com políticas de acesso
- Criptografia em repouso

## Manutenção

Para atualizar a infraestrutura:
```bash
git pull                 # Atualiza código
terraform plan          # Revisa mudanças
terraform apply         # Aplica mudanças
```

Para destruir a infraestrutura:
```bash
terraform destroy      # Remove todos os recursos
```

## Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request
