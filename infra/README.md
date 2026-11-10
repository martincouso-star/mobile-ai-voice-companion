# Deploying the API to Cloud Run

Nothing in this directory is applied by CI, and this repository does not ship a live service. Both paths below create real billable resources when you run them yourself.

Session memory is stored in the API process. A new Cloud Run instance, or a restart, starts with an empty memory. Keep `max_instances` low for a demo, or plan on a shared store before this is used for real conversations. See the roadmap in the repository README.

The container listens on `$PORT` (8080 in this config) and answers `GET /health`.

## Terraform

Requirements: Terraform 1.5 or newer, and Application Default Credentials that can enable APIs, write Artifact Registry, and deploy Cloud Run in `project_id`.

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit project_id. You can leave image pointing at a tag you are about to push.
terraform init
terraform plan
```

`image` must already exist in Artifact Registry before `terraform apply` creates the service. One way to publish it:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
docker build -t us-central1-docker.pkg.dev/PROJECT/voice-companion/api:latest backend
docker push us-central1-docker.pkg.dev/PROJECT/voice-companion/api:latest
```

Then set that name as `image` and run `terraform apply`.

`allow_unauthenticated` defaults to false, so the service is not public until you grant `roles/run.invoker`. Leave it false if `LLM_PROVIDER` is `openai` or `anthropic`. A public service with a paid model key will spend that key for anyone who can reach it.

API keys are not Terraform variables. Create a Secret Manager secret yourself and pass its id:

```bash
printf '%s' "$OPENAI_API_KEY" | gcloud secrets create voice-companion-openai-api-key --data-file=-
```

Then set `llm_provider = "openai"` and `openai_api_key_secret = "voice-companion-openai-api-key"`. The Cloud Run runtime service account needs `roles/secretmanager.secretAccessor` on that secret. The mock provider does not need a secret.

`terraform.tfvars` is gitignored. `terraform.tfvars.example` has no key material.

## gcloud script

`deploy.sh` is a straight-line alternative: enable APIs, create the repository if needed, submit `backend/` to Cloud Build, and deploy Cloud Run with unauthenticated access disabled. It does not configure Secret Manager. Export `LLM_PROVIDER` before running it if you do not want the mock.

```bash
PROJECT_ID=your-gcp-project infra/deploy.sh
```

Review the script before you run it. Terraform and this script can drift; Terraform is the one CI checks.
