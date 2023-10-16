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

# Use `gcloud` to enable:
# - serviceusage.googleapis.com
# - cloudresourcemanager.googleapis.com
resource "null_resource" "enable_service_usage_api" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com --project ${var.project}"
  }

  # depends_on = [google_project]
}

# Wait for the new configuration to propagate
# (might be redundant)
resource "time_sleep" "wait_project_init" {
  create_duration = "30s"

  depends_on = [null_resource.enable_service_usage_api]
}

# resource "google_project_service" "cloud_serviceusage_api" {
#   project                    = var.project
#   service                    = "serviceusage.googleapis.com"
#   disable_dependent_services = true
#   # disable_on_destroy         = true
# }

# resource "google_project_service" "cloudresourcemanager_api" {
#   depends_on                 = [google_project_service.cloud_serviceusage_api]
#   project                    = var.project
#   service                    = "cloudresourcemanager.googleapis.com"
#   disable_dependent_services = true
#   # disable_on_destroy         = true
# }


resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"

  depends_on = [null_resource.enable_service_usage_api]
}

# # Servies 
# resource "google_project_service" "services" {
#   for_each                   = toset(var.services)
#   project                    = var.project
#   service                    = each.value
#   disable_dependent_services = true
#   disable_on_destroy         = true
#   depends_on                 = [time_sleep.wait_30_seconds]
# }

# Enabling required APIs
resource "google_project_service" "services_1st_batch" {
  for_each                   = toset(var.services_1st_batch)
  project                    = var.project
  service                    = each.value
  disable_dependent_services = true
  disable_on_destroy         = false
  depends_on                 = [time_sleep.wait_30_seconds]
}


# Enabling required APIs
resource "google_project_service" "services_2nd_batch" {
  for_each                   = toset(var.services_2nd_batch)
  project                    = var.project
  service                    = each.value
  disable_dependent_services = true
  disable_on_destroy         = false
  depends_on                 = [google_project_service.services_1st_batch]
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
