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

resource "google_compute_instance" "webservers" {
  count        = 3
  name         = "web${count.index}"
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
  labels = {
    role: "web"
}
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80",]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.webservers[*].network_interface[0].access_config[0].nat_ip
}
