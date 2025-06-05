provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "purkinje_vm" {
  name         = "purkinje-vm"
  machine_type = "e2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/deeplearning-platform-release/global/images/family/common-cu113"
      size  = 50
    }
  }

  network_interface {
    network       = "default"
    access_config {}
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["purkinje"]
}