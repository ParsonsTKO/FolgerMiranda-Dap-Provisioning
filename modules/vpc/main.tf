locals {
  id = "${replace(var.name, " ", "-")}"
}


resource "aws_vpc" "this" {
  cidr_block = "${var.cidr}"
  enable_dns_hostnames = true
  tags = "${merge(var.tags, map("Name", var.name))}"
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"
  tags = "${merge(var.tags, map("Name", var.name))}"
}

# -----------------------------------------------
# Manage Default Routing
# -----------------------------------------------

resource "aws_default_route_table" "this" {
  default_route_table_id = "${aws_vpc.this.default_route_table_id}"
  tags = "${merge(var.tags, map("Name", "${var.name} Default"))}"
}

resource "aws_main_route_table_association" "this" {
  vpc_id         = "${aws_vpc.this.id}"
  route_table_id = "${aws_vpc.this.default_route_table_id}"
}

# -----------------------------------------------
# Manage Default
# -----------------------------------------------

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.this.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    security_groups = ["${data.aws_security_group.cluster.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.tags, map("Name", "${var.name} Default"))}"
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.this.default_network_acl_id}"

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.name} Default"))}"

}


# -----------------------------------------------
# Create Web subnets
# -----------------------------------------------
resource "aws_subnet" "this" {
  count = "${length(var.azs)}"
  vpc_id = "${aws_vpc.this.id}"
  cidr_block = "${cidrsubnet(aws_vpc.this.cidr_block, var.newbits, var.netnum + count.index)}"
	availability_zone = "${element(var.azs, count.index)}"
	map_public_ip_on_launch = true
  tags = "${merge(var.tags, map("Name", "${var.name} ${var.env} ${count.index}"))}"
}

# -----------------------------------------------
# Create Public Routing
# -----------------------------------------------
resource "aws_route_table" "this" {
  vpc_id = "${aws_vpc.this.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.this.id}"
  }

  tags = "${merge(var.tags, map("Name", "${var.name}"))}"
}

resource "aws_route_table_association" "this" {
  count = "${length(var.azs)}"
  subnet_id = "${element(aws_subnet.this.*.id, count.index)}"
  route_table_id = "${aws_route_table.this.id}"
}

# Network ACL Web Access
resource "aws_network_acl" "this" {
    vpc_id = "${aws_vpc.this.id}"
    subnet_ids = ["${aws_subnet.this.*.id}"]
    tags = "${merge(var.tags, map("Name", "${var.name} ${var.env}"))}"
}

resource "aws_network_acl_rule" "egress" {
  network_acl_id = "${aws_network_acl.this.id}"
  rule_number = 100
  egress      = true
  protocol    = -1
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = -1
  to_port     = -1
}

resource "aws_network_acl_rule" "ingress_ephemeral" {
  count       = "${length(var.ephemeral_open)}"
  network_acl_id = "${aws_network_acl.this.id}"
  rule_number = "${100 + count.index}"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "${element(var.ephemeral_open, count.index)}"
  from_port   = 1024
  to_port     = 65535
}

resource "aws_network_acl_rule" "ingress_ssh" {
  count       = "${length(var.ssh_open)}"
  network_acl_id = "${aws_network_acl.this.id}"
  rule_number = "${200 + count.index}"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "${element(var.ssh_open, count.index)}"
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "ingress_http" {
  count       = "${length(var.http_open)}"
  network_acl_id = "${aws_network_acl.this.id}"
  rule_number = "${300 + count.index}"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "${element(var.http_open, count.index)}"
  from_port   = 80
  to_port     = 80
}

resource "aws_network_acl_rule" "ingress_https" {
  count       = "${length(var.https_open)}"
  network_acl_id = "${aws_network_acl.this.id}"
  rule_number = "${400 + count.index}"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "${element(var.https_open, count.index)}"
  from_port   = 443
  to_port     = 443
}

# Security group web access
resource "aws_security_group" "web" {
  name = "${local.id}-Web"
  description = "Ports open for Web access"
  vpc_id = "${aws_vpc.this.id}"
  tags = "${merge(var.tags, map("Name", "${var.name} Web"))}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = "${var.http_open}"
    description = "HTTP port open to all IPs"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = "${var.https_open}"
    description = "HTTPS port open to all IPs"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group SSH access
resource "aws_security_group" "ssh" {
  name = "${local.id}-SSH"
  description = "Access to port SSH (22)"
  vpc_id = "${aws_vpc.this.id}"
  tags = "${merge(var.tags, map("Name", "${var.name} SSH"))}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "${var.ssh_open}"
    description = "SSH port open to certian IPs"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
