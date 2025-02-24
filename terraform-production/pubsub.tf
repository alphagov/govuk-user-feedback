

# Define pub/sub topics for each of the layers
data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "staging-topic-binding" {
  topic   = google_pubsub_topic.staging.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_pubsub_topic_iam_binding" "process-topic-binding" {
  topic   = google_pubsub_topic.process.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_pubsub_topic_iam_binding" "analysis-topic-binding" {
  topic   = google_pubsub_topic.analysis.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_pubsub_topic" "staging" {
  name = "staging-pubsub"
  message_storage_policy {
    allowed_persistence_regions = [
      var.project_region,
    ]
  }
}

resource "google_pubsub_topic" "process" {
  name = "process-pubsub"
  message_storage_policy {
    allowed_persistence_regions = [
      var.project_region,
    ]
  }
}

resource "google_pubsub_topic" "analysis" {
  name = "analysis-pubsub"
  message_storage_policy {
    allowed_persistence_regions = [
      var.project_region,
    ]
  }
}