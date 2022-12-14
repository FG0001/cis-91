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
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
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

#Firewall 

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80", "3000"]
  }
  source_ranges = ["0.0.0.0/0"]
}
#Healthcheck 

resource "google_compute_health_check" "webservers" {
  name = "webserver-health-check"

  timeout_sec        = 1
  check_interval_sec = 1

  http_health_check {
    port = 80
  }
}

#Webserver

resource "google_compute_instance_group" "webservers" {
  name        = "cis91-webservers"
  description = "Webserver instance group"

  instances = google_compute_instance.webservers[*].self_link

  named_port {
    name = "http"
    port = "80"
  }
}

#HTTP web-service

resource "google_compute_backend_service" "webservice" {
  name      = "web-service"
  port_name = "http"
  protocol  = "HTTP"

  backend {
    group = google_compute_instance_group.webservers.id
  }

#Health check

  health_checks = [
    google_compute_health_check.webservers.id
  ]
}

#URL map

resource "google_compute_url_map" "default" {
  name            = "my-site"
  default_service = google_compute_backend_service.webservice.id
}
#Web proxy

resource "google_compute_target_http_proxy" "default" {
  name     = "web-proxy"
  url_map  = google_compute_url_map.default.id
}

#External address

resource "google_compute_global_address" "default" {
  name = "external-address"
}

#Forwarding

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "forward-application"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.address
}

output "lb-ip" {
  value = google_compute_global_address.default.address
}
