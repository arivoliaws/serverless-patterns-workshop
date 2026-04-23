# Serverless Patterns - Infrastructure

Terraform infrastructure for the Workshop serverless API project.

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials

## Setup

```bash
terraform init
terraform plan
terraform apply
```

## Variables

| Name | Default | Description |
|------|---------|-------------|
| region | us-west-2 | AWS region |
| workshop_stack_base_name | workshop | Base name for the stack |
| environment | Workshop | Environment name |
| project | Serverless Patterns | Project name |
