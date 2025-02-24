# Define the staging, process and analysis 'layers' as Storage Buckets
resource "google_storage_bucket" "staging_bucket" {
  name          = "${var.project}-staging"
  force_destroy = true
  location      = var.project_region
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = var.staging_max_ttl_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "process_bucket" {
  name          = "${var.project}-process"
  force_destroy = true
  location      = var.project_region
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = var.process_max_ttl_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "analysis_bucket" {
  name          = "${var.project}-analysis"
  force_destroy = true
  location      = var.project_region
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = var.analysis_max_ttl_days
    }
    action {
      type = "Delete"
    }
  }
}

# Define the access rules by group for Storage Buckets
resource "google_storage_bucket_iam_binding" "staging_bucket_write_access" {
  bucket = google_storage_bucket.staging_bucket.name
  role   = "roles/storage.objectAdmin"
  members = [
    "group:${var.data_engineering_addr}"
  ]
}

resource "google_storage_bucket_iam_binding" "process_bucket_write_access" {
  bucket = google_storage_bucket.process_bucket.name
  role   = "roles/storage.objectAdmin"
  members = [
    "group:${var.data_engineering_addr}"
  ]
}

resource "google_storage_bucket_iam_binding" "process_bucket_read_access" {
  bucket = google_storage_bucket.process_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "group:${var.data_analysis_addr}"
  ]
}

resource "google_storage_bucket_iam_binding" "analysis_bucket_write_access" {
  bucket = google_storage_bucket.analysis_bucket.name
  role   = "roles/storage.objectAdmin"
  members = [
    "group:${var.data_analysis_addr}"
  ]
}

resource "google_storage_bucket_iam_binding" "analysis_bucket_read_access" {
  bucket = google_storage_bucket.analysis_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "group:${var.data_engineering_addr}",
    "group:${var.data_consumer_addr}"
  ]
}