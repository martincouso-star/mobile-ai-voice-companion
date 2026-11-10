variable "project_id" {
  description = "GCP project that will host the API."
  type        = string
}

variable "region" {
  description = "Cloud Run region."
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
  default     = "voice-companion-api"
}

variable "repository_id" {
  description = "Artifact Registry repository id for the API image."
  type        = string
  default     = "voice-companion"
}

variable "image" {
  description = "Fully qualified container image to deploy. Build and push it before apply."
  type        = string
}

variable "llm_provider" {
  description = "LLM_PROVIDER value. mock needs no key. openai and anthropic read Secret Manager."
  type        = string
  default     = "mock"

  validation {
    condition     = contains(["mock", "openai", "anthropic"], var.llm_provider)
    error_message = "llm_provider must be mock, openai, or anthropic."
  }
}

variable "openai_api_key_secret" {
  description = "Secret Manager secret id for OPENAI_API_KEY. Leave empty for the mock provider. This is the secret name, not the key."
  type        = string
  default     = ""
}

variable "anthropic_api_key_secret" {
  description = "Secret Manager secret id for ANTHROPIC_API_KEY. Leave empty for the mock provider. This is the secret name, not the key."
  type        = string
  default     = ""
}

variable "allow_unauthenticated" {
  description = "Grant roles/run.invoker to allUsers. Leave false when the service uses a paid model key."
  type        = bool
  default     = false
}

variable "max_instances" {
  description = "Upper Cloud Run instance count. Session memory is per instance."
  type        = number
  default     = 3
}
