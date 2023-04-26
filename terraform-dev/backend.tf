terraform {
 backend "gcs" {
   bucket  = "${var.project}-bucket-tfstate"
   prefix  = "terraform/state"
 }
}
