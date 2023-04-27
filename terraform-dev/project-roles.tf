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