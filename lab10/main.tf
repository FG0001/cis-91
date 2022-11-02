
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
 credentials = file("/home/for9482/cis-91-terraform-364016-5a6d4bca46ef.json")

project = var.project
region  = var.region
zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
  attached_disk {
    source = google_compute_disk.lab10.self_link
    device_name = "lab10"
  }

  service_account {
    email  = google_service_account.lab10-service-account.email
    scopes = ["cloud-platform"]
  }
}



resource "google_service_account" "lab10-service-account" {
account_id   = "lab10-service-account"
display_name = "lab10-service-account"
description = "Service account for lab 10" 
}



resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80", "3000", "5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_disk" "lab10" {
  name  = "lab10"
  type  = "pd-ssd"
  labels = {
    environment = "dev"
  }
  size = "16"
}

resource "google_compute_disk" "storage1" {
  name  = "storage1"
  type  = "pd-ssd"
  labels = {
    environment = "dev"
  }
  size = "20"
}

resource "google_compute_disk" "storage2" {
  name  = "storage2"
  type  = "pd-ssd"
  labels = {
    environment = "dev"
  }
  size = "20"

}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
