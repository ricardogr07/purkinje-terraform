# Configure the Google Cloud provider
provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials_file)
}

# Define a Compute Engine VM instance
resource "google_compute_instance" "purkinje_vm" {
  name         = "purkinje-vm"
  machine_type = var.machine_type
  zone         = var.zone    

  # Configure the boot disk
  boot_disk {
    initialize_params {
      image = var.image
      size  = 50
      type  = "pd-balanced"
    }
  }

  # Configure network settings
  network_interface {
    network = "default"
    access_config {}
  }

  # Attach a service account with cloud platform scope
  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # Startup script to run when the instance boots
  metadata_startup_script = file(var.use_docker ? "startup.sh" : "startup_no_docker.sh")

  # Labels for resource organization
  labels = {
    environment = "prod"
    purpose     = "purkinje-experiment"
  }

  # Additional metadata for internal tracking
  metadata = {
    owner = "ricardo"
    usage = "notebook-autorun"
  }

  # Network tags for firewall rules
  tags = ["http-server", "https-server"]
}
