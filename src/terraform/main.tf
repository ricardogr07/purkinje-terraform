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

  # Attach a GPU accelerator
  guest_accelerator {
    type  = "nvidia-tesla-t4"
    count = 1
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
    automatic_restart    = false
  }

  # Attach a service account with cloud platform scope
  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  # Startup script to run when the instance boots

  metadata_startup_script = file("../startup/main_startup.sh")

  metadata_startup_script = file(var.use_docker ? "../startup/startup.sh" : "../startup/startup_no_docker.sh")

  # Labels for resource organization
  labels = {
    environment = "dev"
    purpose     = "purkinje-experiment"
  }

  # Additional metadata for internal tracking
  metadata = {
  owner                 = "ricardo"
  usage                 = "notebook-autorun"
  install-nvidia-driver = "true"
  run_test              = tostring(var.run_test)
  use_docker            = tostring(var.use_docker)
}

  # Network tags for firewall rules
  tags = ["http-server", "https-server", "gpu"]
}
