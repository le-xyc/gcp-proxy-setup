locals {
  default_port = "3128"

  ports = (
    length(var.ports) >= var.n_proxies
    ? slice(var.ports, 0, var.n_proxies)
    : concat(var.ports, [for _ in range(var.n_proxies - length(var.ports)) : local.default_port])
  )

  distinct_ports = distinct(local.ports)
  n_unique_ports = length(local.distinct_ports)

  instances_names = (
    length(var.instances_names) >= var.n_proxies
    ? slice(var.instances_names, 0, var.n_proxies)
    : concat(var.instances_names, [for i in range(var.n_proxies - length(var.instances_names)) : "instance-${i + 1}"])
  )

  regions = (
    length(var.regions) >= var.n_proxies
    ? slice(var.regions, 0, var.n_proxies)
    : concat(var.regions, [for _ in range(var.n_proxies - length(var.regions)) : var.default_region])
  )
}
