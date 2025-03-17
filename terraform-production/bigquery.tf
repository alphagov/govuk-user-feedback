# Define the staging, process and analysis 'layers' in BigQuery
resource "google_bigquery_dataset" "staging_dataset_bqy" {
  project                         = var.project
  dataset_id                      = "staging"
  friendly_name                   = "staging_bqy"
  description                     = "Staging dataset"
  location                        = var.project_region
  default_table_expiration_ms     = var.staging_max_ttl_ms
  default_partition_expiration_ms = var.staging_max_ttl_ms
  delete_contents_on_destroy      = true

  access {
    role           = "OWNER"
    group_by_email = var.data_engineering_addr
  }
}

resource "google_bigquery_dataset" "process_dataset_bqy" {
  project                         = var.project
  dataset_id                      = "process"
  friendly_name                   = "process_bqy"
  description                     = "Process dataset"
  location                        = var.project_region
  default_table_expiration_ms     = var.process_max_ttl_ms
  default_partition_expiration_ms = var.process_max_ttl_ms
  delete_contents_on_destroy      = true

  access {
    role           = "OWNER"
    group_by_email = var.data_engineering_addr
  }

  access {
    role           = "READER"
    group_by_email = var.data_analysis_addr
  }
}

resource "google_bigquery_dataset" "analysis_dataset_bqy" {
  project                         = var.project
  dataset_id                      = "analysis"
  friendly_name                   = "analysis_bqy"
  description                     = "Analysis dataset"
  location                        = var.project_region
  default_table_expiration_ms     = var.analysis_max_ttl_ms
  default_partition_expiration_ms = var.analysis_max_ttl_ms
  delete_contents_on_destroy      = true

  access {
    role           = "READER"
    group_by_email = var.data_engineering_addr
  }

  access {
    role           = "OWNER"
    group_by_email = var.data_analysis_addr
  }

  access {
    role           = "READER"
    group_by_email = var.data_consumer_addr
  }
}