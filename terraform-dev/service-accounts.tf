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

resource "google_service_account" "support-api-publishing-account" {
  account_id   = "support-api-publishing-account"
  display_name = "support-api-publishing-account"
  description  = "Service account for use in support api publishing"
}



# Restore critical service accounts
resource "google_project_iam_member" "cloudservices_editor" {
  project = var.project
  role    = "roles/editor"
  member  = "serviceAccount:${var.project_number}@cloudservices.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_default_editor" {
  project = var.project
  role    = "roles/editor"
  member  = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "appengine_default_editor" {
  project = var.project
  role    = "roles/editor"
  member  = "serviceAccount:govuk-user-feedback@appspot.gserviceaccount.com"
}


# Restore Cloud Build service account
resource "google_project_iam_member" "cloudbuild_builder" {
  project = var.project
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# Restore Dataform service account for BigQuery
resource "google_project_iam_member" "dataform_bigquery_jobuser" {
  project = var.project
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# Keep the existing artifact-registry-docker permission that was added
resource "google_project_iam_member" "artifact_registry_docker" {
  project = var.project
  role    = "roles/run.developer"
  member  = "serviceAccount:artifact-registry-docker@govuk-user-feedback.iam.gserviceaccount.com"
}

# Restore Google-managed service agents
resource "google_project_iam_member" "service_agents" {
  for_each = {
    "artifactregistry" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
      role   = "roles/artifactregistry.serviceAgent"
    }
    "bigqueryconnection" = {  
      member = "serviceAccount:service-${var.project_number}@gcp-sa-bigqueryconnection.iam.gserviceaccount.com"
      role   = "roles/bigqueryconnection.serviceAgent"
    }
    "bigquerydatatransfer" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
      role   = "roles/bigquerydatatransfer.serviceAgent"
    }
    "cloudbuild" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
      role   = "roles/cloudbuild.serviceAgent"
    }
    "cloudfunctions" = {
      member = "serviceAccount:service-${var.project_number}@gcf-admin-robot.iam.gserviceaccount.com"
      role   = "roles/cloudfunctions.serviceAgent"
    }
    "cloudscheduler" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
      role   = "roles/cloudscheduler.serviceAgent"
    }
    "compute" = {
      member = "serviceAccount:service-${var.project_number}@compute-system.iam.gserviceaccount.com"
      role   = "roles/compute.serviceAgent"
    }
    "container" = {
      member = "serviceAccount:service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com"
      role   = "roles/container.serviceAgent"
    }
    "containerregistry" = {
      member = "serviceAccount:service-${var.project_number}@containerregistry.iam.gserviceaccount.com"
      role   = "roles/containerregistry.ServiceAgent"
    }
    "dataform" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-dataform.iam.gserviceaccount.com"
      role   = "roles/dataform.serviceAgent"
    }
    "dlp" = {
      member = "serviceAccount:service-${var.project_number}@dlp-api.iam.gserviceaccount.com"
      role   = "roles/dlp.serviceAgent"
    }
    "eventarc" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-eventarc.iam.gserviceaccount.com"
      role   = "roles/eventarc.serviceAgent"
    }
    "pubsub" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
      role   = "roles/pubsub.serviceAgent"
    }
    "run" = {
      member = "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com"
      role   = "roles/run.serviceAgent"
    }
    "servicenetworking" = {
      member = "serviceAccount:service-${var.project_number}@service-networking.iam.gserviceaccount.com"
      role   = "roles/servicenetworking.serviceAgent"
    }
    "vpcaccess" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-vpcaccess.iam.gserviceaccount.com"
      role   = "roles/vpcaccess.serviceAgent"
    }
    "workflows" = {
      member = "serviceAccount:service-${var.project_number}@gcp-sa-workflows.iam.gserviceaccount.com"
      role   = "roles/workflows.serviceAgent"
    }
  }
  project = var.project
  role    = each.value.role
  member  = each.value.member
}
