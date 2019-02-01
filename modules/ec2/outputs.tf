output "lb_cname" {
  value = "${aws_alb.this.dns_name}"
}

output "lb_zone_id" {
  value = "${aws_alb.this.zone_id}"
}

output "key" {
  value = "${aws_key_pair.this.key_name}"
}

output "cluster_sg" {
  value = "${aws_security_group.cluster.id}"
}

output "listener_http" {
  value = "${aws_alb_listener.http.arn}"
}

output "listener_https" {
  value = "${aws_alb_listener.https.0.arn}"
}
