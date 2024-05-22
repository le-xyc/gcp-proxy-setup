resource "google_service_account" "service-account" {
  account_id   = "my-service-account"
  display_name = "My service account"
}

resource "google_compute_address" "external-static-ip-address" {
  count  = var.n_proxies
  name   = "ip-${count.index + 1}"
  region = local.regions[count.index]
}

resource "google_compute_instance" "proxy-server" {
  count = var.n_proxies

  boot_disk {
    auto_delete = true
    device_name = local.instances_names[count.index]

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240515"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  machine_type = "e2-micro"
  name         = local.instances_names[count.index]

  network_interface {
    access_config {
      network_tier = "PREMIUM"
      nat_ip       = google_compute_address.external-static-ip-address[count.index].address
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/${var.project}/regions/${local.regions[count.index]}/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = google_service_account.service-account.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone = "${local.regions[count.index]}-a"
}

resource "google_compute_firewall" "allow-squid" {
  count     = local.n_unique_ports
  name      = "default-allow-squid-${local.distinct_ports[count.index]}"
  network   = "default"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [local.distinct_ports[count.index]]
  }

  source_ranges = ["0.0.0.0/0"]
}
