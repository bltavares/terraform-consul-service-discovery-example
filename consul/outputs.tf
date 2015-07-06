output "nodes_floating_ips" {
  value = "${join(\",\", openstack_compute_instance_v2.consul_node.*.access_ip_v4)}"
}

output "consul_web_ui" {
  value ="${openstack_compute_instance_v2.consul_ui.access_ip_v4}"
}
