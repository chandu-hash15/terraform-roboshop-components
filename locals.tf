locals {
  
  ami = data.aws_ami.joindevops.id
  common_name = "${var.Project}.${var.Environment}"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  frontend_arn = data.aws_ssm_parameter.frontend_alb_listener_arn.value
  backend_arn = data.aws_ssm_parameter.backend_alb_listener_arn.value
  listener_arn = "${var.Component}" == "frontend" ? local.frontend_arn : local.backend_arn
  tg_port = "${var.Component}" == "frontend" ? 80 : 8080
  health_check_path = "${var.Component}" == "frontend" ? "/" : "/health"
  host_path = "${var.Component}" == "frontend" ? "${var.Project}-${var.Environment}.${var.domain_name}" : "${var.Component}.backend-alb-${var.Environment}"
  private_subnet_ids = [
        data.aws_ssm_parameter.private_subnet_1_id.value,
        
        data.aws_ssm_parameter.private_subnet_2_id.value
    ]
  tags = {

        Project = var.Project
        Environment = var.Environment
        Terraform = true
    }
}
