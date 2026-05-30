# Workshop Infrastructure

Terraform infrastructure for the Serverless Patterns workshop, deploying AWS Lambda-based APIs.

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

| Name | Description | Default |
|------|-------------|---------|
| region | AWS region | us-west-2 |
| workshop_stack_base_name | Base name for the workshop stack | workshop |
| environment | Environment name | Workshop |
| project | Project name | Serverless Patterns |
