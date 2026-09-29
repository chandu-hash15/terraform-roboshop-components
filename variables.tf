variable "instance_type" {
  type = string
}

variable "subnet_id" { 
  type = string
}

variable "Project" {
  type = string
}

variable "Environment" {
  type = string
}


variable "security_group_id" {
  type = string
  
}


variable "Component" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = string
}

variable "backend_alb_listener_arn" {
  type = string
}

variable "domain_name" {
  type = string
  
}