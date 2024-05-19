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

variable "port" {
  type        = string
  description = "Squid port"
  default     = "3113"
}

variable "instance_name" {
  type        = string
  description = "Name of the VM instance"
}
