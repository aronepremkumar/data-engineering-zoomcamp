variable "project" {
  description = "The ID of the GCP project"
  type        = string
  default     = "de-zoomcamp-2026-485504"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-east1"
}

variable "gcs_bucket_name" {
  description = "Unique bucket for DE Zoomcamp 2026"
  type        = string
  default     = "de-zoomcamp-2026-bucket" # Must be globally unique
}

variable "bq_dataset_name" {
  description = "de_zoomcamp_dataset"
  type        = string
  default     = "de_zoomcamp_dataset"
}