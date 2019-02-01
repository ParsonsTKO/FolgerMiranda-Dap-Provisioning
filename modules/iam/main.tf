locals {
  id = "${replace(var.name, " ", "-")}"
}

# ----------------------------------------
# Create role for instance
# ----------------------------------------
resource "aws_iam_role" "this" {
  name = "${local.id}"
  description = "${var.description}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "${var.trusted}.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  count = "${var.trusted == "ec2" ? 1 : 0}"
  name = "${local.id}"
  path  = "/"
  role = "${aws_iam_role.this.name}"
}

resource "aws_iam_server_certificate" "this" {
  count = "${var.certificate_domain ? 1 : 0}"
  name             = "${var.certificate_domain}"
  certificate_body = "${file("files/${var.certificate_domain}/certificate.crt")}"
  certificate_chain = "${file("files/${var.certificate_domain}/intermediate.crt")}"
  private_key      = "${file("files/${var.certificate_domain}/certificate.key")}"
}
