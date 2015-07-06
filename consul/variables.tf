variable "username" {}
variable "password" {}
variable "tenant_name" {}
variable "auth_url" {}
variable "public_key" {}
variable "identifier" {}
variable "key_file_path" {}

variable "pub_net_id" {
    default = {
      IAD = "public"
    }
}

variable "region" {
    default = "IAD"
    description = "The region of openstack, for image/flavor/network lookups."
}

variable "image" {
    default = {
      IAD = "28153eac-1bae-4039-8d9f-f8b513241efe"
    }
}

variable "flavor" {
    default = {
         IAD = "general1-2"
    }
}

variable "servers" {
    default = "3"
    description = "The number of Consul servers to launch."
}
