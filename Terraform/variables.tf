variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository for Medusa"
  type        = string
}

variable "db_password" {
  description = "The password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "desired_count" {
  description = "Initial desired count for the ECS service"
  type        = number
  default     = 1
}

variable "scale_out_cooldown" {
  description = "Cooldown period for scale out in seconds"
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  description = "Cooldown period for scale in in seconds"
  type        = number
  default     = 60
}
