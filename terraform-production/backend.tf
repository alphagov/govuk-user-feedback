
terraform {
  backend "gcs" {
    bucket = "govuk-user-feedback-bucket-tfstate"
    prefix = "terraform/state"
  }
}

