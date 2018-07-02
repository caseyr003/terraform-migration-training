# This Terraform script creates a user, adds the user to a group, creates two
# compartments, creates policies to give the user access to each compartment.
# It then, in one compartment, provisions a virtual cloud network, provisions a compute
# instance, runs a script to configure the server. Number of users needed is set
# dynamically in the count variable.

# Create Users
resource "oci_identity_user" "users" {
  count = "${var.count}"
	compartment_id = "${var.tenancy_ocid}"
	description = "User ${count.index} for OCI Migration IaaSathon"
	name = "user.${count.index}"
}

# Generate UI Passwords for all Users
resource "oci_identity_ui_password" "ui_passwords" {
  count = "${var.count}"
	user_id = "${element(oci_identity_user.users.*.id, count.index)}"
}

# Generate Upload API Key for all Users
resource "oci_identity_api_key" "api_keys" {
	count = "${var.count}"
	key_value = "${var.public_key_path}"
	user_id = "${element(oci_identity_user.users.*.id, count.index)}"
}

# Create Groups
resource "oci_identity_group" "groups" {
	count = "${var.count}"
	compartment_id = "${var.tenancy_ocid}"
	description = "Group ${count.index} for OCI Migration IaaSathon"
	name = "group_${var.count}"
}

# Add User to Group
resource "oci_identity_user_group_membership" "user_group_memberships" {
	count = "${var.count}"
	group_id = "${element(oci_identity_group.groups.*.id, count.index)}"
	user_id = "${element(oci_identity_user.users.*.id, count.index)}"
}

# Create Cloud Compartment
resource "oci_identity_compartment" "cloud_compartments" {
  count = "${var.count}"
	compartment_id = "${var.tenancy_ocid}"
	description = "Cloud Compartment ${count.index} for OCI Migration IaaSathon"
	name = "cloud_${count.index}"
}

# Create Customer Datacenter Compartment
resource "oci_identity_compartment" "customer_compartments" {
  count = "${var.count}"
	compartment_id = "${var.tenancy_ocid}"
	description = "Customer Datacenter Compartment ${count.index} for OCI Migration IaaSathon"
	name = "customer_datacenter_${count.index}"
}

# Create Policy to add User to Cloud Compartment
resource "oci_identity_policy" "cloud_policy" {
  count = "${var.count}"
	compartment_id = "${var.tenancy_ocid}"
	description = "Allow user.${count.index} access to cloud_${count.index} compartment"
	name = "Cloud Policy ${var.count}"
	statements = ["Allow group group_${count.index} to manage all-resources on compartment cloud_${count.index}"]
}

# Create Policy to add User to Customer Datacenter Compartment
resource "oci_identity_policy" "customer_policy" {
  count = "${var.count}"
	compartment_id = "${var.tenancy_ocid}"
	description = "Allow user.${count.index} access to customer_datacenter_${count.index} compartment"
	name = "Customer Datacenter Policy ${var.count}"
	statements = ["Allow group group_${count.index} to manage all-resources on compartment customer_datacenter_${count.index}"]
}

# Create VCNs in Datacenter Compartment
resource "oci_core_virtual_network" "vcns" {
  count = "${var.count}"
  cidr_block = "10.0.0.0/16"
  compartment_id = "${element(oci_identity_compartment.customer_compartments.*.id, count.index)}"
  display_name = "vcn"
}

# Create internet gateway to allow public internet traffic
resource "oci_core_internet_gateway" "igs" {
  count = "${var.count}"
  compartment_id = "${element(oci_identity_compartment.customer_compartments.*.id, count.index)}"
  display_name = "ig"
  vcn_id = "${element(oci_core_virtual_network.vcns.*.id, count.index)}"
}

# Create route table to connect vcn and internet gateway
resource "oci_core_route_table" "rts" {
  count = "${var.count}"
  compartment_id = "${element(oci_identity_compartment.customer_compartments.*.id, count.index)}"
  vcn_id = "${element(oci_core_virtual_network.vcns.*.id, count.index)}"
  display_name = "rt"
  route_rules {
    cidr_block = "0.0.0.0/0"
    network_entity_id = "${element(oci_core_internet_gateway.igs.*.id, count.index)}"
  }
}

# Create security list to allow internet access from compute and ssh access
resource "oci_core_security_list" "sls" {
  count = "${var.count}"
  compartment_id = "${element(oci_identity_compartment.customer_compartments.*.id, count.index)}"
  display_name = "sl"
  vcn_id = "${element(oci_core_virtual_network.vcns.*.id, count.index)}"
  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol = "6"
  }]
  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }
    protocol = "6"
    source = "0.0.0.0/0"
  },
  {
    tcp_options {
      "max" = 8080
      "min" = 8080
    }
    protocol = "6"
    source = "0.0.0.0/0"
  },
  {
    tcp_options {
      "max" = 3000
      "min" = 3000
    }
    protocol = "6"
    source = "0.0.0.0/0"
  }]
}

# Create subnet in vcns
resource "oci_core_subnet" "subnets" {
  count = "${var.count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1],"name")}"
  cidr_block = "10.0.1.0/24"
  display_name = "subnet"
  compartment_id = "${element(oci_identity_compartment.customer_compartments.*.id, count.index)}"
  vcn_id = "${element(oci_core_virtual_network.vcns.*.id, count.index)}"
  dhcp_options_id = "${element(oci_core_virtual_network.vcns.*.default_dhcp_options_id, count.index)}"
  route_table_id = "${element(oci_core_route_table.rts.*.id, count.index)}"
  security_list_ids = ["${element(oci_core_security_list.sls.*.id, count.index)}"]
}

# Create compute instances
resource "oci_core_instance" "compute_instances" {
  count = "${var.count}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id = "${element(oci_identity_compartment.customer_compartments.*.id, count.index)}"
  display_name = "${var.compute_display_name}"
  shape = "${var.instance_shape}"
  subnet_id = "${element(oci_core_subnet.subnets.*.id, count.index)}"

  source_details {
    source_type = "image"
    source_id = "${var.image_ocid}"
	}

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
  }

  timeouts = {
    create = "60m"
  }
}

# Copy script to instances and then run script
resource "null_resource" "compute_configs" {
  # Copy file userdata folder contents into tmp folder on instance
  count = "${var.count}"
  provisioner "file" {
    connection {
      host = "${element(oci_core_instance.compute_instance.*.public_ip, count.index)}"
      user = "opc"
      private_key = "${var.ssh_private_key}"
    }
    source     = "userdata/"
    destination = "/tmp/"
  }
  # Run the script on the instance
  provisioner "remote-exec" {
    connection {
      host = "${element(oci_core_instance.compute_instance.*.public_ip, count.index)}"
      user = "opc"
      private_key = "${var.ssh_private_key}"
    }

    inline = [
      "chmod +x /tmp/config.sh",
      "sudo /tmp/config.sh ",
    ]
  }
}

output "accounts" {
  value = "${formatlist("
Account Details:
 Tenancy OCID: %v
 Region: %v
 User OCID: %v
 Console Password: %v
 Fingerprint: %v
 Private API Key: %v
 Datacenter Compartment OCID: %v
 Public IP: %v
 Private SSH Key: %v
 Cloud Compartment OCID: %v\n",
 var.tenancy_ocid,
 var.region,
 oci_identity_user.users.*.id,
 oci_identity_ui_password.ui_passwords.*.password,
 var.fingerprint,
 var.private_key_path,
 oci_identity_compartment.customer_compartments.*.id,
 oci_core_instance.compute_instances.*.public_ip,
 var.ssh_private_key,
 oci_identity_compartment.cloud_compartments.*.id)}"
}
