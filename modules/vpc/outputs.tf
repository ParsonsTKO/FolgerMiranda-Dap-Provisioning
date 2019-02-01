output "vpc_id" {
  value = "${aws_vpc.this.id}"
}

output "rt_default_id" {
  value = "${aws_vpc.this.default_route_table_id}"
}

output "ig" {
  value = "${aws_internet_gateway.this.id}"
}

output "web_sg" {
  value = "${aws_security_group.web.id}"
}

output "ssh_sg" {
  value = "${aws_security_group.ssh.id}"
}

output "subnets_cidr" {
  value = "${aws_subnet.this.*.cidr_block}"
}

output "subnet_ids" {
  value = "${aws_subnet.this.*.id}"
}
