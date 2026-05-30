variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "workshop_stack_base_name" {
  description = "Base name for the workshop stack"
  type        = string
  default     = "workshop"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Workshop"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "Serverless Patterns"
}
