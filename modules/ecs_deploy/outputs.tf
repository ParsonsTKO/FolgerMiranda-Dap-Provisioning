output "repositories" {
  value = "${merge(var.definition_vars, zipmap(keys(var.repositories), aws_ecr_repository.this.*.repository_url))}"
}
