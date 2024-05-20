locals {
  instances_names = concat(
    var.instances_names, 
    [for i in range(max(0, length(var.ports) - length(var.instances_names))) : "instance-${var.ports[length(var.instances_names) + i]}"] # Updated
  )
}
