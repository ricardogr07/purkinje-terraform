provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials_file)
}

resource "google_compute_instance" "purkinje_vm" {
  name         = "purkinje-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = 50
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("startup.sh")

  labels = {
    environment = "prod"
    purpose     = "purkinje-experiment"
  }

  metadata = {
    owner = "ricardo"
    usage = "notebook-autorun"
  }

  tags = ["http-server", "https-server"]
}