provider "openstack" {
    user_name  = "${var.username}"
    tenant_name = "${var.tenant_name}"
    password  = "${var.password}"
    auth_url  = "${var.auth_url}"
}

variable "network_uuid" {
  default = "2f063ba5-33b2-4e7d-b2ee-47134df78f48"
}

resource "openstack_compute_keypair_v2" "app_keypair" {
  name = "${var.identifier}-app-keypair"
  region = "${var.region}"
  public_key = "${var.public_key}"
}


resource "openstack_compute_instance_v2" "app_node" {
  name = "${var.identifier}-app-node-${count.index}"
  region = "${var.region}"
  image_id = "${lookup(var.image, var.region)}"
  flavor_id = "${lookup(var.flavor, var.region)}"
  key_pair = "${openstack_compute_keypair_v2.app_keypair.name}"
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

    provisioner "remote-exec" {
        inline = [
            "echo ${var.consul-ip} > /tmp/app-consul-addr",
            "echo ${var.identifier} > /tmp/app-server-identifier",
            "echo ${count.index} > /tmp/app-server-index",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/install.sh",
            "${path.module}/scripts/consul-agent.sh",
            "${path.module}/scripts/registrator.sh",
            "${path.module}/scripts/server.sh",
        ]
    }
}
