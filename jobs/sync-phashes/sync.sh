#!/bin/bash
# Exports card_phashes from BigQuery to GCS and pushes to card-identifier-data repo.
# Intended to run as a Cloud Run Job (see job.yaml).
#
# Required env vars:
#   GCS_DATA_BUCKET     — GCS bucket name (no gs:// prefix)
#   GITHUB_TOKEN        — GitHub PAT with contents:write on card-identifier-data

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-future-gadget-labs-483502}"
DATASET="card_identifier"
TABLE="card_phashes"
GCS_BUCKET="${GCS_DATA_BUCKET}"
GITHUB_REPO="FutureGadgetResearch/card-identifier-data"
OUTPUT_FILE="card_phashes.json"
TMP="/tmp/${OUTPUT_FILE}"

echo "→ Querying BigQuery..."

# Cast phash to STRING to avoid JSON precision loss for values > 2^53.
bq query \
  --project_id="${PROJECT_ID}" \
  --format=json \
  --use_legacy_sql=false \
  "SELECT
     row_id,
     card_id,
     CAST(phash AS STRING) AS phash,
     source,
     COALESCE(image_url, '') AS image_url,
     FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', created_at) AS created_at
   FROM \`${PROJECT_ID}.${DATASET}.${TABLE}\`
   ORDER BY card_id, source" \
> "${TMP}"

echo "→ Uploading to GCS..."
gsutil cp "${TMP}" "gs://${GCS_BUCKET}/${OUTPUT_FILE}"

echo "→ Pushing to GitHub (${GITHUB_REPO})..."

CONTENT=$(base64 -w 0 "${TMP}")

# Get current SHA if file already exists (required for updates).
SHA=$(curl -sf \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_REPO}/contents/${OUTPUT_FILE}" \
  | jq -r '.sha // empty' || true)

if [ -n "${SHA}" ]; then
  PAYLOAD=$(jq -n \
    --arg msg "sync: update card_phashes" \
    --arg content "${CONTENT}" \
    --arg sha "${SHA}" \
    '{message: $msg, content: $content, sha: $sha}')
else
  PAYLOAD=$(jq -n \
    --arg msg "sync: add card_phashes" \
    --arg content "${CONTENT}" \
    '{message: $msg, content: $content}')
fi

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/${GITHUB_REPO}/contents/${OUTPUT_FILE}" \
  -d "${PAYLOAD}")

if [[ "${HTTP_STATUS}" != "200" && "${HTTP_STATUS}" != "201" ]]; then
  echo "✗ GitHub push failed (HTTP ${HTTP_STATUS})"
  exit 1
fi

echo "✓ Sync complete: ${OUTPUT_FILE} → GCS + ${GITHUB_REPO}"
