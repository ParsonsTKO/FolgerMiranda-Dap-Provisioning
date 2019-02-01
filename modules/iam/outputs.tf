output "role" {
  value = "${aws_iam_role.this.name}"
}

output "role_arn" {
  value = "${aws_iam_role.this.arn}"
}
