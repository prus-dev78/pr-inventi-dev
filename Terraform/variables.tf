# Variables for OCI Kubernetes Infrastructure

variable "tenancy_ocid" {
  description = "The OCID of your tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region to deploy resources"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use"
  type        = string
  default     = "v1.28.2"
}

variable "node_shape" {
  description = "The shape of the worker nodes"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  description = "The number of OCPUs for each worker node"
  type        = number
  default     = 2
}

variable "node_memory_in_gbs" {
  description = "The amount of memory in GBs for each worker node"
  type        = number
  default     = 16
}

variable "node_pool_size" {
  description = "The number of worker nodes in the node pool"
  type        = number
  default     = 4
}

variable "api_allowed_cidr" {
  description = "CIDR block allowed to access the Kubernetes API endpoint. For security, restrict this to your IP or corporate network."
  type        = string
  default     = "0.0.0.0/0"
}
