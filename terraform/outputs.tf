output "external_ips" {
  value       = [for instance in google_compute_instance.proxy-server : instance.network_interface.0.access_config.0.nat_ip]
  description = "External IP addresses of VM instances"
}

output "instances_names" {
  value       = google_compute_instance.proxy-server[*].name
  description = "Names of VM instances"
}

output "proxies_ports" {
  value = [for rule in google_compute_firewall.allow-squid : one(rule.allow.*.ports)[0]]
  description = "Proxies ports"
}
