resource "google_service_account" "web" {
  account_id   = "web-server-sa"
  display_name = "Web Server Service Account"
  description  = "Service account for the GCP Secure Network Lab web servers"
}

resource "google_project_iam_member" "web_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.web.email}"
}