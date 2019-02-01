data "aws_subnet" "this" {
  id = "${element(var.subnets, 0)}"
}

data "aws_vpc" "this" {
  id = "${data.aws_subnet.this.vpc_id}"
}

# Template for initial configuration bash script
data "template_file" "user_data" {
    template = "${file("files/user_data.yml.tpl")}"

    vars {
        #name = "${local.id}-`ec2metadata --instance-id`"
        name = "${local.id}-`curl http://169.254.169.254/latest/meta-data/instance-id`"
    }
}
