variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "container_image" {
  description = "Container image to run (leave empty to use ECR repo URL + :latest)"
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "instance_type" {
  description = "EC2 instance type for the Ubuntu server"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to connect to SSH; restrict this to your public IP in production"
  type        = string
  default     = "0.0.0.0/0"
}
