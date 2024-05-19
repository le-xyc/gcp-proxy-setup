provider "google" {
  project = var.project
}

resource "google_service_account" "service-account" {
  account_id   = "my-service-account"
  display_name = "My service account"
}

resource "google_compute_address" "external-static-ip-address" {
  name = "ip-${var.port}"
  region = var.region
}

locals {
  instance_name = var.instance_name != "" ? var.instance_name : "instance-${var.port}"
}

resource "google_compute_instance" "proxy-server" {
  boot_disk {
    auto_delete = true
    device_name = local.instance_name

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
  name         = local.instance_name

  network_interface {
    access_config {
      network_tier = "PREMIUM"
      nat_ip = google_compute_address.external-static-ip-address.address
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/${var.project}/regions/${var.region}/subnetworks/default"
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

  zone = var.zone
}

resource "google_compute_firewall" "allow-squid" {
  name        = "default-allow-squid-${var.port}"
  network     = "default"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [var.port]
  }

  source_ranges = ["0.0.0.0/0"]
}
