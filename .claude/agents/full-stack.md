# Card Identifier Full-Stack Agent

This document outlines the structure and protocols for the card-identifier suite — a four-repository system combining an admin frontend, a public frontend, a backend service, and a centralized data repository.

## Repository Architecture

The suite consists of four sibling repositories under `FutureGadgetResearch/`:

- **Admin Frontend** (`card-identifier-admin-frontend`): Hugo-based interface with Firebase authentication for authorized catalog management
- **Backend** (`card-identifier-backend`): Go/Gin API and scheduled jobs running on Cloud Run
- **Public Frontend** (`card-identifier-frontend`): Read-only Hugo site for browsing cards and submitting images for identification — no auth required
- **Data Repository** (`card-identifier-data`): JSON files managed exclusively by the backend sync pipeline

All repositories reside under `FutureGadgetResearch/` as siblings.

## GCP Project

All infrastructure lives under GCP project **`future-gadget-labs-483502`**.

## Key Technical Details

### Authentication & Security

The admin frontend requires Firebase sign-in before making write requests. The Firebase ID token is attached to every backend API call as `Authorization: Bearer <token>` via `static/js/api.js`.

Access is further restricted to a whitelist of allowed emails (`ALLOWED_EMAILS`), enforced on both frontend (UI gating in `firebase-init.js`) and backend (middleware in `internal/middleware/auth.go`).

The public frontend has no auth — identification requests go directly to the backend without a token.

### Data Flow

- **Reads:** Static JSON files from `card-identifier-data` via GitHub Raw (primary) with GCS fallback
- **Writes:** All mutations go through the Cloud Run backend API
- **Sync:** After every write, the backend asynchronously exports to GCS and commits updated JSON to `card-identifier-data`

### Infrastructure

- Cloud Run hosts the Go API service
- BigQuery (`future-gadget-labs-483502`, dataset `card_catalog`) is the source of truth
- GCS stores card images and data snapshot backups
- GitHub Pages hosts the two Hugo frontends
- GitHub Actions with Workload Identity Federation handles CI/CD

### Development

The admin frontend uses Hugo with custom Bootstrap 5 templates. Start with:

```bash
set -a && source .env && set +a && hugo server
```

The backend runs locally with:

```bash
go run .
```

Run `go run ./cmd/setup` once to provision BigQuery datasets and tables.

## Cross-Repository Coordination

Changes that span repositories should be coordinated:

- New API endpoints need both a backend handler and frontend caller
- Data schema changes ripple to all consumers (admin frontend, public frontend, data repo)
- Commit messages should reference related changes across repos for traceability

Credentials must never be hardcoded — they belong in gitignored `.env` files (see `.env.example` in each repo).

## Environment Variable Pattern

All repos use the same pattern:
- Backend: plain env vars loaded via `internal/config/config.go`
- Hugo frontends: `HUGO_PARAMS_*` vars mapped to `.Site.Params.*` in templates
