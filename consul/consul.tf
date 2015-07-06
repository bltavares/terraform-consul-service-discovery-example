provider "openstack" {
    user_name  = "${var.username}"
    tenant_name = "${var.tenant_name}"
    password  = "${var.password}"
    auth_url  = "${var.auth_url}"
}

variable "network_uuid" {
  default = "2f063ba5-33b2-4e7d-b2ee-47134df78f48"
}

resource "openstack_compute_keypair_v2" "consul_keypair" {
  name = "${var.identifier}-consul-keypair"
  region = "${var.region}"
  public_key = "${var.public_key}"
}

resource "openstack_compute_instance_v2" "consul_node" {
  name = "${var.identifier}-consul-node-${count.index}"
  region = "${var.region}"
  image_id = "${lookup(var.image, var.region)}"
  flavor_id = "${lookup(var.flavor, var.region)}"
  key_pair = "${openstack_compute_keypair_v2.consul_keypair.name}"
  count = "${var.servers}"
  network {
    uuid = "00000000-0000-0000-0000-000000000000"
  }
  network {
    uuid = "${var.network_uuid}"
  }

    connection {
        user = "root"
        key_file = "${var.key_file_path}"
        timeout = "1m"
        agent = false
    }

    provisioner "file" {
        source = "${path.module}/scripts/upstart.conf"
        destination = "/tmp/upstart.conf"
    }

    provisioner "file" {
        source = "${path.module}/scripts/upstart-join.conf"
        destination = "/tmp/upstart-join.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.servers} > /tmp/consul-server-count",
            "echo ${count.index} > /tmp/consul-server-index",
            "echo ${var.identifier} > /tmp/consul-server-identifier",
            "echo ${openstack_compute_instance_v2.consul_node.0.network.1.fixed_ip_v4} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/install.sh",
            "${path.module}/scripts/server.sh",
            "${path.module}/scripts/service.sh",
        ]
    }
}

resource "openstack_compute_instance_v2" "consul_ui" {
  name = "${var.identifier}-consul-node-ui"
  region = "${var.region}"
  image_id = "${lookup(var.image, var.region)}"
  flavor_id = "${lookup(var.flavor, var.region)}"
  key_pair = "${openstack_compute_keypair_v2.consul_keypair.name}"
  network {
    uuid = "00000000-0000-0000-0000-000000000000"
  }
  network {
    uuid = "${var.network_uuid}"
  }

    connection {
        user = "root"
        key_file = "${var.key_file_path}"
        timeout = "1m"
        agent = false
    }

    provisioner "file" {
        source = "${path.module}/scripts/upstart.conf"
        destination = "/tmp/upstart.conf"
    }

    provisioner "file" {
        source = "${path.module}/scripts/upstart-join.conf"
        destination = "/tmp/upstart-join.conf"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ui > /tmp/consul-server-index",
            "echo ${var.identifier} > /tmp/consul-server-identifier",
            "echo ${openstack_compute_instance_v2.consul_node.0.network.1.fixed_ip_v4} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/install.sh",
            "${path.module}/scripts/ui-client.sh",
            "${path.module}/scripts/service.sh",
        ]
    }
}
