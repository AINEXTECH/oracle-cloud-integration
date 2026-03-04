#*************************************
#         Auth Requirements
#*************************************
variable "tenancy_ocid" {
  type        = string
  description = "OCI Tenancy OCID. Found at: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five"
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
