output "user_ocid" {
  description = "OCID of the Myrmex integration IAM user"
  value       = oci_identity_user.myrmex_user.id
}

output "user_name" {
  description = "Name of the Myrmex integration IAM user"
  value       = oci_identity_user.myrmex_user.name
}

output "group_ocid" {
  description = "OCID of the Myrmex integration IAM group"
  value       = oci_identity_group.myrmex_group.id
}

output "group_name" {
  description = "Name of the Myrmex integration IAM group"
  value       = oci_identity_group.myrmex_group.name
}

output "policy_ocid" {
  description = "OCID of the Myrmex integration policy"
  value       = oci_identity_policy.myrmex_policy.id
}

output "tenancy_home_region" {
  description = "Home region of the tenancy"
  value       = local.tenancy_home_region
}
