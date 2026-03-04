output "user_ocid" {
  description = "OCID of the Myrmex integration IAM user"
  value       = oci_identity_user.myrmex_user.id
}

output "user_name" {
  description = "Name of the Myrmex integration IAM user"
  value       = oci_identity_user.myrmex_user.name
}

output "group_name" {
  description = "Name of the Myrmex integration IAM group"
  value       = oci_identity_group.myrmex_group.name
}

output "policy_ocid" {
  description = "OCID of the Myrmex integration policy"
  value       = oci_identity_policy.myrmex_policy.id
}

output "instance_ocid" {
  description = "OCID of the Myrmex agent Compute Instance"
  value       = oci_core_instance.myrmex_agent.id
}

output "instance_private_ip" {
  description = "Private IP address of the Myrmex agent instance"
  value       = oci_core_instance.myrmex_agent.private_ip
}

output "instance_state" {
  description = "Current state of the Myrmex agent instance"
  value       = oci_core_instance.myrmex_agent.state
}
