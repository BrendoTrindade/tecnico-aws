# Teste Técnico AWS/DevOps

Este repositório contém a solução para o teste técnico de AWS/DevOps, focando em infraestrutura como código e boas práticas de DevOps.

## Estrutura do Projeto

```
.
├── docs/
│   └── respostas.md     # Documentação detalhada das respostas
├── terraform/
│   ├── main.tf          # Configuração principal da infraestrutura
│   └── variables.tf     # Definição das variáveis
└── README.md
```

## Questões Resolvidas

1. **Infraestrutura AWS**: Configuração de EC2, RDS e S3 com políticas de segurança
2. **IaC**: Load balancer distribuindo tráfego entre duas EC2s
3. **Continuidade**: Plano de DR para falhas de região e AZ
4. **Monitoramento**: Configuração do CloudWatch

## Como Usar

1. Configure suas credenciais AWS
2. Ajuste as variáveis em `terraform/variables.tf`:
   - `meu_ip`: Seu IP para acesso SSH
   - `rede_empresa`: CIDR da rede corporativa
   - `bucket_name`: Nome desejado para o bucket S3

3. Execute:
```bash
cd terraform
terraform init
terraform apply
```

## Segurança

- EC2 acessível apenas via SSH com IP específico
- HTTP permitido apenas da rede da empresa
- RDS acessível apenas pela EC2
- S3 com acesso restrito

## Tecnologias Utilizadas

- AWS (EC2, RDS, S3, CloudWatch)
- Terraform
- Git
