variable "password" {}
variable "public_key" {}
variable "key_file_path" {}
variable "identifier" {}
variable "auth_url" {}
variable "region" {}
variable "tenant_name" {}
variable "username" {}

module "consul" {
  source        = "./consul"
  password      = "${var.password}"
  public_key    = "${var.public_key}"
  key_file_path = "${var.key_file_path}"
  tenant_name   = "${var.tenant_name}"
  username      = "${var.username}"
  identifier    = "${var.identifier}"
  auth_url      = "${var.auth_url}"
  region        = "${var.region}"
  tenant_name   = "${var.tenant_name}"
}

module "app" {
  source        = "./app"
  password      = "${var.password}"
  public_key    = "${var.public_key}"
  key_file_path = "${var.key_file_path}"
  tenant_name   = "${var.tenant_name}"
  username      = "${var.username}"
  identifier    = "${var.identifier}"
  auth_url      = "${var.auth_url}"
  region        = "${var.region}"
  tenant_name   = "${var.tenant_name}"
  consul-ip     = "${module.consul.consul_web_ui}"
  servers       = "2"
}
