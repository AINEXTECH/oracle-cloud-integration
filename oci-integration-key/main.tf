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
  freeform_tags = {
    "managed-by" = "myrmex-integration"
    "purpose"    = "oci-integration"
  }
}

# ─────────────────────────────────────────────
# IAM User
# ─────────────────────────────────────────────
resource "oci_identity_user" "myrmex_user" {
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] IAM user created for Myrmex integration — used to authenticate and manage OCI resources"
  name           = var.user_name
  email          = var.user_email

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

# ─────────────────────────────────────────────
# IAM Group
# ─────────────────────────────────────────────
resource "oci_identity_group" "myrmex_group" {
  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Group for Myrmex integration user — grants broad management permissions across the tenancy"
  name           = var.user_group_name

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}

# ─────────────────────────────────────────────
# Group Membership
# ─────────────────────────────────────────────
resource "oci_identity_user_group_membership" "myrmex_membership" {
  depends_on = [oci_identity_user.myrmex_user, oci_identity_group.myrmex_group]

  group_id = oci_identity_group.myrmex_group.id
  user_id  = oci_identity_user.myrmex_user.id
}

# ─────────────────────────────────────────────
# IAM Policy (broad management permissions)
# Equivalent to GCP roles assigned in gcp_integration_quickstart.py
# ─────────────────────────────────────────────
resource "oci_identity_policy" "myrmex_policy" {
  depends_on = [
    oci_identity_group.myrmex_group,
    oci_identity_user_group_membership.myrmex_membership
  ]

  compartment_id = var.tenancy_ocid
  description    = "[DO NOT REMOVE] Myrmex integration policy — grants permissions for resource discovery and management"
  name           = var.policy_name

  statements = [
    # Compute (equivalent to roles/compute.admin)
    "Allow group Default/${var.user_group_name} to manage instance-family in tenancy",
    # Network Security (equivalent to roles/compute.securityAdmin)
    "Allow group Default/${var.user_group_name} to manage network-security-groups in tenancy",
    # Object & Block Storage (equivalent to roles/storage.admin)
    "Allow group Default/${var.user_group_name} to manage object-family in tenancy",
    "Allow group Default/${var.user_group_name} to manage volume-family in tenancy",
    # IAM (equivalent to roles/iam.securityAdmin)
    "Allow group Default/${var.user_group_name} to manage policies in tenancy",
    "Allow group Default/${var.user_group_name} to manage groups in tenancy",
    "Allow group Default/${var.user_group_name} to manage dynamic-groups in tenancy",
    # Monitoring (equivalent to roles/monitoring.admin)
    "Allow group Default/${var.user_group_name} to manage metrics in tenancy",
    "Allow group Default/${var.user_group_name} to manage alarms in tenancy",
    # Logging (equivalent to roles/logging.admin)
    "Allow group Default/${var.user_group_name} to manage log-groups in tenancy",
    "Allow group Default/${var.user_group_name} to manage log-content in tenancy",
    # Database (equivalent to roles/cloudsql.admin)
    "Allow group Default/${var.user_group_name} to manage database-family in tenancy",
    # OKE / Kubernetes (equivalent to roles/container.admin)
    "Allow group Default/${var.user_group_name} to manage cluster-family in tenancy",
    # Networking (equivalent to roles/compute.networkAdmin)
    "Allow group Default/${var.user_group_name} to manage virtual-network-family in tenancy",
    # General read access (base visibility)
    "Allow group Default/${var.user_group_name} to read all-resources in tenancy",
    "Allow group Default/${var.user_group_name} to read audit-events in tenancy",
  ]

  defined_tags  = {}
  freeform_tags = local.freeform_tags
}
