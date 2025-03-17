terraform {
  required_version = ">= 1.2.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "5.46.0"
    }
  }
}

data "oci_identity_tenancy" "tenancy_metadata" {
  tenancy_id = var.tenancy_ocid
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
}

locals {
  tenancy_home_region = data.oci_identity_tenancy.tenancy_metadata.home_region_key
  read_policy_group = var.dynamic_group_name
  freeform_tags = {
    myrmex-terraform = "true"
  }
}

resource "oci_identity_dynamic_group" "serviceconnector_group" {
  #Required
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Dynamic group for Myrmex hub connector"
  matching_rule  = "All {resource.type = 'serviceconnector'}"
  name           = var.dynamic_group_name

  #Optional
  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

resource "oci_identity_user" "read_only_user" {
    #Required
    compartment_id = var.tenancy_ocid
    description = "[DO NOT REMOVE] Read only user created for fetching resources metadata which is used by Myrmex hub"
    name = "MyrmexAuthUser"
    email = "test@myrmex.com"

    #Optional
    defined_tags = {}
    freeform_tags = local.freeform_tags
}

resource "oci_identity_group" "read_policy_group" {
  depends_on     = [oci_identity_user.read_only_user]
  #Required
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Group for adding a user for having read-only permissions of resources"
  name           = var.user_group_name

  #Optional
  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

resource "oci_identity_user_group_membership" "mrx_user_group_membership" {
    depends_on     = [oci_identity_user.read_only_user, oci_identity_group.read_policy_group]
    #Required
    group_id = oci_identity_group.read_policy_group.id
    user_id = oci_identity_user.read_only_user.id
}

resource "oci_identity_policy" "logs_policy" {
  depends_on     = [oci_identity_dynamic_group.serviceconnector_group, oci_identity_user_group_membership.mrx_user_group_membership]
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Policy to have any connector hub read from monitoring source and write to a target function"
  name           = var.myrmex_logs_policy
  statements = [
    "Allow dynamic-group Default/${var.dynamic_group_name} to read logs in tenancy",
    "Allow group Default/${oci_identity_group.read_policy_group.name} to read all-resources in tenancy",
    "Allow group Default/${oci_identity_group.read_policy_group.name} to read all-events in tenancy"
  ]
  defined_tags  = {}
  freeform_tags = local.freeform_tags
}
