resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "compute" {
  project    = var.project_id
  service    = "compute.googleapis.com"
  depends_on = [google_project_service.cloudresourcemanager]
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "n8n_vm" {
  depends_on   = [google_project_service.compute]
  name         = "n8n-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  tags = ["n8n"]
}

resource "google_compute_firewall" "n8n_fw" {
  depends_on = [google_project_service.compute]
  name    = "n8n-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "5678"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n"]
}

variable "project_id" {}
variable "region"    { default = "europe-west1" }
variable "zone"      { default = "europe-west1-b" }