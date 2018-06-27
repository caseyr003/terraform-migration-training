# Variables Exported from env.sh
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_public_key" {}
variable "instance_shape" {}
variable "image_ocid" {}
variable "ssh_authorized_private_key" {}
variable "count" {}
# Uses Default Value
variable "compute_display_name" {
  default="App Server"
}
variable "availability_domain" {
  default="1"
}
