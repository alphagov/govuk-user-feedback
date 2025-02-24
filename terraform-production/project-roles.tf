# Enable BigQuery read sessions for applicable groups
resource "google_project_iam_member" "engineering-project-roles" {
  for_each = toset([
    "roles/appengine.deployer",
    "roles/appengine.appAdmin",
    "roles/artifactregistry.writer",
    "roles/bigquery.jobUser",
    "roles/bigquery.readSessionUser",
    "roles/cloudbuild.builds.builder",
    "roles/cloudfunctions.invoker",
    "roles/cloudfunctions.developer",
    "roles/cloudscheduler.admin",
    "roles/cloudsql.editor",
    "roles/compute.networkUser",
    "roles/logging.logWriter",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/pubsub.editor",
    "roles/pubsub.publisher",
    "roles/run.admin",
    "roles/secretmanager.secretAccessor",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/vpcaccess.viewer",
    "roles/workflows.invoker",
    "roles/workflows.editor"
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