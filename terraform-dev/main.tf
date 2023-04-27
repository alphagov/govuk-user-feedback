terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.0.0"
    }
  }
}

provider "google" {
  project               = var.project
  billing_project       = var.project
  user_project_override = "true"
}

# Enabling required APIs
resource "google_project_service" "services" {
  for_each                   = toset(var.services)
  project                    = var.project
  service                    = each.value
  disable_dependent_services = true 
  disable_on_destroy         = true 
}

# Storage bucket for state
resource "google_storage_bucket" "default" {
  name          = "${var.project}-bucket-tfstate"
  force_destroy = false
  location      = var.project_region
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}