variable "workshop_stack_base_name" {
  description = "Base name prefix for workshop resources"
  type        = string
  default     = "workshop"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name for tagging"
  type        = string
  default     = "workshop"
}
