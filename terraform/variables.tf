variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "default_region" {
  type        = string
  description = "Default GCP region for VM instances"
}

variable "ports" {
  type        = list(string)
  description = "Provided Squid ports for VM instances"
  default     = []
}

variable "instances_names" {
  type        = list(string)
  description = "Provided names for VM instances"
  default     = []
}

variable "n_proxies" {
  type        = number
  description = "Number of VM instances to create"
}

variable "regions" {
  type        = list(string)
  description = "Provided regions for VM instances"
  default     = []
}
