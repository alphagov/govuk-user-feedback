# Internal service accounts
resource "google_service_account" "notifications_service_account" {
  account_id   = "internal-notifications"
  display_name = "Internal Notifications"
  description  = "Service account for use in publication of internal notifications"
}

data "google_iam_policy" "notification_policy" {
  binding {
    role = "roles/pubsub.publisher"

    members = [
      "serviceAccount:${google_service_account.notifications_service_account.email}"
    ]
  }
}

# Role-based service accounts
resource "google_service_account" "engineering_service_account" {
  account_id   = "data-engineering"
  display_name = "Data Engineering"
  description  = "Service account for use in Data Engineering applications/processes"
}

resource "google_service_account" "analysis_service_account" {
  account_id   = "data-analysis"
  display_name = "Data Analysis"
  description  = "Service account for use in Data Analysis applications/processes"
}

# Group memberships for role-based service accounts
resource "google_cloud_identity_group_membership" "data-engineering-service-account-group-membership" {
  group = var.data_engineering_group_id

  preferred_member_key {
    id = google_service_account.engineering_service_account.email
  }

  roles {
    name = "MEMBER"
  }
}

resource "google_cloud_identity_group_membership" "data-analysis-service-account-group-membership" {
  group = var.data_analysis_group_id

  preferred_member_key {
    id = google_service_account.analysis_service_account.email
  }

  roles {
    name = "MEMBER"
  }
}