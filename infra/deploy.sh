#!/usr/bin/env bash
# Manual alternative to Terraform. This script deploys for real.
# Do not run it unless you intend to create GCP resources.
# Terraform under infra/ is the configuration this repository tests.
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
REGION="${REGION:-us-central1}"
SERVICE="${SERVICE:-voice-companion-api}"
REPO="${REPO:-voice-companion}"
LLM_PROVIDER="${LLM_PROVIDER:-mock}"

gcloud services enable run.googleapis.com artifactregistry.googleapis.com --project "${PROJECT_ID}"

if ! gcloud artifacts repositories describe "${REPO}" --location "${REGION}" --project "${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${REPO}" \
    --repository-format=docker \
    --location="${REGION}" \
    --project="${PROJECT_ID}" \
    --description="Voice companion API"
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHA="$(git -C "${ROOT}" rev-parse --short HEAD)"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/api:${SHA}"

gcloud builds submit "${ROOT}/backend" \
  --project "${PROJECT_ID}" \
  --tag "${IMAGE}"

gcloud run deploy "${SERVICE}" \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --image "${IMAGE}" \
  --port 8080 \
  --set-env-vars "LLM_PROVIDER=${LLM_PROVIDER}" \
  --min-instances 0 \
  --max-instances 3 \
  --no-allow-unauthenticated

echo "Deployed ${IMAGE}. Session memory is per instance and is lost on restart."
