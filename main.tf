resource "aws_instance" "component" {
  ami           = local.ami
  instance_type = var.instance_type
  vpc_security_group_ids = [data.aws_ssm_parameter.sg_id.value]
  subnet_id              = local.private_subnet_ids[0]

  

  tags = merge(
    local.tags,
    {
      Name = "${local.common_name}-${var.Component}"
    }
  )
}

resource "terraform_data" "component" {
  triggers_replace = [
    aws_instance.component.id
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.component.private_ip
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo sh /tmp/bootstrap.sh ${var.Component} ${var.Environment} "
    ]
  }
}

resource "aws_ec2_instance_state" "component" {
  instance_id = aws_instance.component.id
  state       = "stopped"

  depends_on = [
    terraform_data.component
  ]
}


resource "aws_ami_from_instance" "component" {
  name               = "${var.Component}-ami"
  source_instance_id = aws_instance.component.id

  depends_on = [
    aws_ec2_instance_state.component
  ]
}

resource "aws_lb_target_group" "component" {
  name        = "${var.Component}-target-group"
  port        = local.tg_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  deregistration_delay = 60

  health_check {

    port = local.tg_port
    healthy_threshold = 2
    matcher = "200-299"
    path = local.health_check_path
    protocol    = "HTTP"
    interval = 10
    timeout = 2
    unhealthy_threshold = 2

  }
}


 resource "aws_launch_template" "component" {
  name = "${local.common_name}-${var.Component}"


  image_id = aws_ami_from_instance.component.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "${var.instance_type}"

  vpc_security_group_ids = [data.aws_ssm_parameter.sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = merge (

      local.tags,
      {
        Name = "${local.common_name}-${var.Component}"
      }

    )
      
    }
  }


  resource "aws_autoscaling_group" "component" {
  name                      = "${local.common_name}-${var.Component}"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  launch_template {
    id      = aws_launch_template.component.id
    version = aws_launch_template.component.latest_version
    
  }
  vpc_zone_identifier       = local.private_subnet_ids[0]
  target_group_arns = [aws_lb_target_group.component.arn]

   instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  dynamic "tag" {
    for_each = merge(
      local.tags,
      {
        Name = "${local.common_name}-${var.Component}"
      }

    )
    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }
  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "component" {
  autoscaling_group_name = aws_autoscaling_group.component.name
  name                   = "${local.common_name}-${var.Component}"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}


resource "aws_lb_listener_rule" "static" {
  listener_arn = local.listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.component.arn
  }


  condition {
    host_header {
      values = [local.host_path]
    }
  }
}



