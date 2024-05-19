output "external_ip" {
  value       = google_compute_instance.proxy-server.network_interface.0.access_config.0.nat_ip
  description = "The external IP address of the VM instance"
}

output "instance_name" {
  value       = google_compute_instance.proxy-server.name
  description = "The name of the VM instance"
}

output "proxy_port" {
  value       = one(google_compute_firewall.allow-squid.allow.*.ports)[0]
  description = "The proxy port"
}
