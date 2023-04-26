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

# Enable BigQuery read sessions for applicable groups
resource "google_project_iam_member" "engineering-project-roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/bigquery.jobUser",
    "roles/bigquery.readSessionUser",
    "roles/secretmanager.secretAccessor",
    "roles/cloudfunctions.invoker",
    "roles/cloudfunctions.developer",
    "roles/cloudsql.editor",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/logging.logWriter",
    "roles/workflows.invoker",
    "roles/workflows.editor",
    "roles/appengine.deployer",
    "roles/cloudbuild.builds.builder",
    "roles/appengine.appAdmin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/pubsub.editor",
    "roles/cloudscheduler.admin",
    "roles/iam.serviceAccountTokenCreator",
    "projects/${var.project}/roles/${google_project_iam_custom_role.custom_IAP_role.role_id}"
  ])
  role    = each.key
  member  = "group:${var.data_engineering_addr}"
  project = var.project
}

resource "google_project_iam_member" "analysis-project-roles" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.readSessionUser",
    "roles/artifactregistry.writer",
    "roles/run.invoker"
  ])
  role    = each.key
  member  = "group:${var.data_analysis_addr}"
  project = var.project
}

resource "google_project_iam_member" "consumer-project-roles" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.readSessionUser",
    "roles/run.invoker"
  ])
  role    = each.key
  member  = "group:${var.data_consumer_addr}"
  project = var.project
}

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

# Bucket notifications for each layer
/*resource "google_storage_notification" "staging-bucket-notification" {
  bucket         = google_storage_bucket.staging_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.staging.id
  depends_on     = [google_pubsub_topic_iam_binding.staging-topic-binding]
  event_types    = ["OBJECT_FINALIZE"]
}

resource "google_storage_notification" "process-bucket-notification" {
  bucket         = google_storage_bucket.process_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.process.id
  depends_on     = [google_pubsub_topic_iam_binding.process-topic-binding]
  event_types    = ["OBJECT_FINALIZE"]
}

resource "google_storage_notification" "analysis-bucket-notification" {
  bucket         = google_storage_bucket.analysis_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.analysis.id
  depends_on     = [google_pubsub_topic_iam_binding.analysis-topic-binding]
  event_types    = ["OBJECT_FINALIZE"]
}*/

/*
id,name - identifiers for the resource with the format projects/{{project}}/roles/{{role_id}}
    id:projects/govuk-analytics-test/roles/iapIngressManager
  name:projects/govuk-analytics-test/roles/iapIngressManager
*/

resource "google_project_iam_custom_role" "custom_IAP_role" {
  role_id     = "iapIngressManager"
  title       = "IAP ingress manager"
  description = "A role for managing regional https load balancers and manaing IAP permissions"
  permissions = [
    "artifactregistry.packages.delete",
    "artifactregistry.packages.get",
    "artifactregistry.packages.list",
    "artifactregistry.repositories.create",
    "artifactregistry.repositories.delete",
    "artifactregistry.repositories.deleteArtifacts",
    "artifactregistry.repositories.get",
    "artifactregistry.repositories.list",
    "artifactregistry.repositories.update",
    "artifactregistry.repositories.uploadArtifacts",
    "artifactregistry.versions.delete",
    "artifactregistry.versions.get",
    "artifactregistry.versions.list",
    "compute.addresses.create",
    "compute.addresses.createInternal",
    "compute.addresses.deleteInternal",
    "compute.addresses.get",
    "compute.addresses.list",
    "compute.addresses.use",
    "compute.addresses.useInternal",
    "compute.addresses.setLabels",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.networks.access",
    "compute.networks.addPeering",
    "compute.networks.create",
    "compute.networks.delete",
    "compute.networks.get",
    "compute.networks.getEffectiveFirewalls",
    "compute.networks.getRegionEffectiveFirewalls",
    "compute.networks.list",
    "compute.networks.listPeeringRoutes",
    "compute.networks.mirror",
    "compute.networks.removePeering",
    "compute.networks.setFirewallPolicy",
    "compute.networks.switchToCustomMode",
    "compute.networks.update",
    "compute.networks.updatePeering",
    "compute.networks.updatePolicy",
    "compute.networks.use",
    "compute.regionBackendServices.create",
    "compute.regionBackendServices.delete",
    "compute.regionBackendServices.get",
    "compute.regionBackendServices.list",
    "compute.regionBackendServices.update",
    "compute.regionBackendServices.use",
    "compute.regionOperations.get",
    "compute.regionOperations.list",
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.get",
    "compute.subnetworks.getIamPolicy",
    "compute.subnetworks.list",
    "compute.subnetworks.mirror",
    "compute.subnetworks.setIamPolicy",
    "compute.subnetworks.setPrivateIpGoogleAccess",
    "compute.subnetworks.update",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.networkEndpointGroups.attachNetworkEndpoints",
    "compute.networkEndpointGroups.create",
    "compute.networkEndpointGroups.delete",
    "compute.networkEndpointGroups.detachNetworkEndpoints",
    "compute.networkEndpointGroups.get",
    "compute.networkEndpointGroups.getIamPolicy",
    "compute.networkEndpointGroups.list",
    "compute.networkEndpointGroups.setIamPolicy",
    "compute.networkEndpointGroups.use",
    "compute.regionNetworkEndpointGroups.create",
    "compute.regionNetworkEndpointGroups.delete",
    "compute.regionNetworkEndpointGroups.get",
    "compute.regionNetworkEndpointGroups.list",
    "compute.regionNetworkEndpointGroups.use",
    "compute.backendServices.addSignedUrlKey",
    "compute.backendServices.create",
    "compute.backendServices.delete",
    "compute.backendServices.deleteSignedUrlKey",
    "compute.backendServices.get",
    "compute.backendServices.getIamPolicy",
    "compute.backendServices.list",
    "compute.backendServices.setIamPolicy",
    "compute.backendServices.setSecurityPolicy",
    "compute.backendServices.update",
    "compute.backendServices.use",
    "compute.regionUrlMaps.create",
    "compute.regionUrlMaps.delete",
    "compute.regionUrlMaps.get",
    "compute.regionUrlMaps.invalidateCache",
    "compute.regionUrlMaps.list",
    "compute.regionUrlMaps.update",
    "compute.regionUrlMaps.use",
    "compute.regionUrlMaps.validate",
    "compute.regionSslCertificates.create",
    "compute.regionSslCertificates.delete",
    "compute.regionSslCertificates.get",
    "compute.regionSslCertificates.list",
    "compute.regionSslPolicies.create",
    "compute.regionSslPolicies.delete",
    "compute.regionSslPolicies.get",
    "compute.regionSslPolicies.list",
    "compute.regionSslPolicies.listAvailableFeatures",
    "compute.regionSslPolicies.update",
    "compute.regionSslPolicies.use",
    "compute.regionTargetHttpsProxies.create",
    "compute.regionTargetHttpsProxies.delete",
    "compute.regionTargetHttpsProxies.get",
    "compute.regionTargetHttpsProxies.list",
    "compute.regionTargetHttpsProxies.setSslCertificates",
    "compute.regionTargetHttpsProxies.setUrlMap",
    "compute.regionTargetHttpsProxies.update",
    "compute.regionTargetHttpsProxies.use",
    "compute.forwardingRules.create",
    "compute.forwardingRules.delete",
    "compute.forwardingRules.get",
    "compute.forwardingRules.list",
    "compute.forwardingRules.pscCreate",
    "compute.forwardingRules.pscDelete",
    "compute.forwardingRules.pscSetLabels",
    "compute.forwardingRules.pscSetTarget",
    "compute.forwardingRules.pscUpdate",
    "compute.forwardingRules.setLabels",
    "compute.forwardingRules.setTarget",
    "compute.forwardingRules.update",
    "compute.forwardingRules.use",
    "compute.regionSecurityPolicies.get",
    "compute.regionSecurityPolicies.list",
    "compute.regionSecurityPolicies.use",
    "domains.locations.get",
    "domains.locations.list",
    "domains.operations.cancel",
    "domains.operations.get",
    "domains.operations.list",
    # "domains.registrations.configureContact",
    # "domains.registrations.configureDns",
    # "domains.registrations.configureManagement",
    # "domains.registrations.create",
    # "domains.registrations.delete",
    # "domains.registrations.get",
    # "domains.registrations.getIamPolicy",
    # "domains.registrations.list",
    # "domains.registrations.setIamPolicy",
    # "domains.registrations.update"
  ]
}