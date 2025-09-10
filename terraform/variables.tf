variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région GCP"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone GCP"
  type        = string
  default     = "europe-west1-b"
}

variable "n8n_domain" {
  description = "Nom de domaine pour Nginx et Let's Encrypt"
  type        = string
  default     = "n8nallanlny.freeddns.org"
}

variable "n8n_ssl_email" {
  description = "Adresse email pour Let's Encrypt"
  type        = string
  default     = "admin@n8nallanlny.freeddns.org"
}
