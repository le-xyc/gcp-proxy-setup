output "external_ips" {
  value       = [for instance in google_compute_instance.proxy-server : instance.network_interface.0.access_config.0.nat_ip]
  description = "External IP addresses of VM instances"
}

output "instances_names" {
  value       = google_compute_instance.proxy-server[*].name
  description = "Names of VM instances"
}

output "proxies_ports" {
  value       = local.ports
  description = "Proxies ports"
}

output "instances_zones" {
  value       = [for instance in google_compute_instance.proxy-server : instance.zone]
  description = "Zones of VM instances"
}
