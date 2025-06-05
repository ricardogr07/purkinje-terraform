variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  default     = "us-central1"
  description = "GCP region"
}

variable "zone" {
  default     = "us-central1-a"
  description = "GCP zone"
}

variable "service_account_email" {
  description = "Service account email with compute and storage access"
  type        = string
}
