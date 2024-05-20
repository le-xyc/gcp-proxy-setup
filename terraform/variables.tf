variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
}

variable "ports" {
  type        = list(string)
  description = "Squid ports"
}

variable "instances_names" {
  type        = list(string)
  description = "Names of VM instances"
  default     = []
}

variable "n_proxies" {
  type        = number
  description = "Number of VM instances to create"
}
