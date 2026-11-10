resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "api" {
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Container images for the voice companion API."

  depends_on = [google_project_service.artifact_registry]
}

resource "google_cloud_run_v2_service" "api" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  depends_on = [google_project_service.run]

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true
      }

      env {
        name  = "LLM_PROVIDER"
        value = var.llm_provider
      }

      env {
        name  = "MAX_HISTORY_TURNS"
        value = "20"
      }

      dynamic "env" {
        for_each = var.openai_api_key_secret == "" ? [] : [var.openai_api_key_secret]
        content {
          name = "OPENAI_API_KEY"
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = var.anthropic_api_key_secret == "" ? [] : [var.anthropic_api_key_secret]
        content {
          name = "ANTHROPIC_API_KEY"
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 0
        period_seconds        = 5
        failure_threshold     = 6
        timeout_seconds       = 3
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  name     = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
