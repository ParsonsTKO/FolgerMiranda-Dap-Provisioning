locals {
  id = "${replace(var.name, " ", "-")}"
}

# ----------------------------------------
# Create Architecture  for HA: ALB,AG
# ----------------------------------------
resource "aws_alb" "this" {
  name            = "${local.id}"
  internal        = false
  security_groups = ["${var.lb_sgs}"]
  subnets = ["${var.subnets}"]
  idle_timeout = "${var.timeout}"
  tags = "${merge(var.tags, map("Name", "${var.name}"))}"
}


# --------------------------------------------------------
# CREATE Target Group HTTP
# --------------------------------------------------------
resource "aws_alb_target_group" "http" {
  name     = "${local.id}-http"
  port     = 80
  protocol = "HTTP"
  vpc_id = "${data.aws_vpc.this.id}"
  tags = "${merge(var.tags, map("Name", "${var.name}"))}"
  deregistration_delay = 3

  stickiness {
    type = "lb_cookie"
    enabled = "${var.stickiness > 0 ? true : false}"
    cookie_duration = "${var.stickiness > 0 ? var.stickiness : 86400}"
  }

}

# ----------------------------------------
# ADD an https Listener for the ALB (Needs a certificate)
# ----------------------------------------
resource "aws_alb_listener" "https" {
  count = "${var.certificate != "" ? 1 : 0}"
  load_balancer_arn = "${aws_alb.this.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${var.certificate}"

  default_action {
    target_group_arn = "${aws_alb_target_group.http.arn}"
    type             = "forward"
  }

}

resource "aws_alb_listener" "http" {
  load_balancer_arn = "${aws_alb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.http.arn}"
    type             = "forward"
  }

}

# Security group ALB access
resource "aws_security_group" "cluster" {
  name = "${local.id}-Cluster"
  description = "Ports open for the ECS cluster instances"
  vpc_id = "${data.aws_vpc.this.id}"
  tags = "${merge(var.tags, map("Name", "${var.name} Cluster"))}"

  ingress {
    from_port = 32000
    to_port = 40000
    protocol = "tcp"
    security_groups = ["${var.lb_sgs}"]
    description = "30000 to 32000 from Web SG"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------
# Create SSH Key
# --------------
resource "aws_key_pair" "this" {
  key_name = "${local.id}-${var.key_name}"
  public_key = "${file("files/${var.key_name}.key.pub")}"
}

# -------------------------------
# CREATE LAUNCH CONFIGURATION
# -------------------------------
resource "aws_iam_role_policy_attachment" "this" {
  count = "${var.role != "" ? 1 : 0}"
  role = "${var.role}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_launch_configuration" "this" {
  name          = "${var.name} ${var.identifier}"
  image_id      = "${var.ami}"
  instance_type = "${var.type}"
  security_groups = ["${concat(list(aws_security_group.cluster.id), var.lc_sgs)}"]
  user_data = "${data.template_file.user_data.rendered}"
  key_name = "${aws_key_pair.this.key_name}"
  iam_instance_profile = "${var.role}"
  enable_monitoring = false

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_size = "120"
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -------------------------------
# CREATE AUTO SCALING GROUP
# -------------------------------
resource "aws_autoscaling_group" "this" {
  vpc_zone_identifier       = ["${var.subnets}"]
  name                      = "${var.name}"
  max_size                  = "${var.max}"
  min_size                  = "${var.min}"
  desired_capacity          = "${var.desired}"
  health_check_grace_period = "${var.grace_period}"
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.this.name}"
  #Check if both https and http T.G are required to have instances attached, Not neccesary with ALB
  #target_group_arns = ["${aws_alb_target_group.http.arn}","${aws_alb_target_group.https.arn}"]
  default_cooldown = 30

  tags = ["${concat(
    list(
      map("key", "Name", "value", "${var.name}", "propagate_at_launch", true)
    ),
    var.asg_tags)
  }"]


  timeouts {
      delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }

}
