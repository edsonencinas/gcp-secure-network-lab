variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "gcp-secure-network-lab"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}