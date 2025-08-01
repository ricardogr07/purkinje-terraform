variable "project_id" {
  default = "purkinje-learning"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "credentials_file" {
  default = "gcp-key.json"
}

variable "machine_type" {
  default = "n1-standard-16"
}

variable "image" {
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20250530"
}

variable "service_account_email" {
  default = "github-actions-deploy@purkinje-learning.iam.gserviceaccount.com"
}

variable "use_docker" {
  description = "Determine if Docker will be used in the startup-script"
  type        = bool
  default     = false
}

variable "run_test" {
  description = "Whether to run a test script on startup"
  type        = bool
  default     = false
}