locals {
  id = "${replace(var.name, " ", "-")}"
}

resource "aws_ecs_cluster" "this" {
  name = "${local.id}"
}

resource "aws_ecr_repository" "this" {
  count = "${length(var.repositories)}"
  name  = "${lower(element(var.repositories, count.index))}"
}

resource "aws_iam_policy" "ecr" {
  name        = "${local.id}-AmazonECR"
  description = "Access to Amazon ECR"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = "${var.cluster_role}"
  policy_arn = "${aws_iam_policy.ecr.arn}"
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = "${var.cluster_role}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
