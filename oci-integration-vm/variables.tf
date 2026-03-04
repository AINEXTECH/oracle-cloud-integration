#*************************************
#         Auth Requirements
#*************************************
variable "tenancy_ocid" {
  type        = string
  description = "OCI Tenancy OCID. Found at: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five"
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where the Compute Instance will be created"
}

variable "region" {
  type        = string
  description = "OCI Region where the compute instance will be deployed (e.g. sa-saopaulo-1, us-ashburn-1)"
}

#*************************************
#         Myrmex Agent Configuration
#*************************************
variable "myrmex_token" {
  type        = string
  sensitive   = true
  description = "Myrmex EDR installation token (provided by Myrmex platform)"
}

variable "context_id" {
  type        = string
  sensitive   = true
  description = "Myrmex context ID (provided by Myrmex platform)"
}

variable "oci_account_name" {
  type        = string
  description = "Friendly name for this OCI account, used in the agent hostname"
  default     = "oci-account"
}

#*************************************
#         Identity Configuration
#*************************************
variable "user_name" {
  type        = string
  description = "Name of the IAM user to be created for Myrmex integration"
  default     = "myrmex-integration-user"
}

variable "user_email" {
  type        = string
  description = "Email address associated with the Myrmex integration IAM user"
  default     = "myrmex-integration@myrmex.ai"
}

variable "user_group_name" {
  type        = string
  description = "Name of the IAM group to be created for Myrmex integration"
  default     = "MyrmexIntegrationGroup"
}

variable "policy_name" {
  type        = string
  description = "Name of the IAM policy to be created for Myrmex integration"
  default     = "myrmex-integration-policy"
}

variable "dynamic_group_name" {
  type        = string
  description = "Name of the dynamic group for the Myrmex Compute Instance"
  default     = "myrmex-vm-dynamic-group"
}

#*************************************
#         Compute Instance
#*************************************
variable "instance_name" {
  type        = string
  description = "Name of the Myrmex agent Compute Instance"
  default     = "myrmex-agent"
}

variable "instance_shape" {
  type        = string
  description = "OCI Compute shape for the Myrmex agent instance"
  default     = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  type        = number
  description = "Number of OCPUs for Flex shapes"
  default     = 1
}

variable "instance_memory_in_gbs" {
  type        = number
  description = "Memory in GB for Flex shapes"
  default     = 1
}

variable "subnet_id" {
  type        = string
  description = "OCID of the subnet where the Myrmex agent instance will be placed (private subnet recommended)"
}

variable "availability_domain" {
  type        = string
  description = "Availability Domain for the instance (e.g. AD-1, AD-2, AD-3)"
  default     = "AD-1"
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether to assign a public IP to the Myrmex agent instance. Disabled by default for security."
  default     = false
}