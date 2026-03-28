# bq-cr-gcs-git-architecture-frontend-admin-template

## Project Overview

This is a **template** for Hugo-based admin frontends following the BigQuery / Cloud Run / GCS / Git architecture. Fork or use this as a GitHub template to bootstrap new projects.

## Architecture

- **Framework:** [Hugo](https://gohugo.io/) — static site generator with Go templates
- **Theme:** Custom theme (`themes/admin/`) — minimal Bootstrap 5 layout, no external theme dependency
- **Auth:** Firebase Authentication — users must sign in before any backend requests are made. The Firebase ID token is attached to all backend API calls.
- **Backend communication:** All mutations are gated behind a valid Firebase session. The `api()` helper in `static/js/api.js` handles token attachment automatically.
- **Data reads:** Static JSON served from GitHub Raw (primary) with GCS as fallback, via `static/js/data-loader.js`.
- **Deployment:** GitHub Pages via GitHub Actions (`.github/workflows/deploy.yml`).

## Key Files

| Path | Purpose |
|------|---------|
| `hugo.toml` | Hugo config — title, description, params defaults |
| `themes/admin/layouts/` | Hugo templates (baseof, list, index) |
| `themes/admin/layouts/partials/` | head, navbar, footer, scripts partials |
| `static/js/firebase-init.js` | Firebase app init, `authSignOut()`, `isEmailAllowed()`, auth state listener |
| `static/js/api.js` | Authenticated `api(method, path, body)` helper + `qs()` query builder |
| `static/js/app.js` | Global `showToast()` utility |
| `static/js/data-loader.js` | `loadJsonData(filename)` (GitHub→GCS fallback) + `loadJsonFromUrl(url)` (bare fetch) |
| `static/css/app.css` | Minimal style overrides on top of Bootstrap 5 |
| `content/items/_index.md` | Example section — copy to add new sections |
| `content/dashboard/_index.md` | Dashboard section — read-only enriched view of pHash data |
| `themes/admin/layouts/dashboard/list.html` | Dashboard template — see "Dashboard" section below |
| `.env.example` | Template for all environment variables |

## Auth Flow

1. User lands on the site and is prompted to sign in via Firebase Auth (Google sign-in).
2. On successful sign-in, Firebase issues an ID token.
3. The frontend attaches the ID token as `Authorization: Bearer <token>` on all backend requests.
4. The backend validates the token via the Firebase Admin SDK before processing any write operations.
5. Access is further restricted to a whitelist of allowed emails (`ALLOWED_EMAILS`), enforced on both frontend and backend.

## Dashboard

The dashboard (`/dashboard/`) is a **read-only enriched view** of whatever is currently in the database, loaded live from the backend API.

### Data join

pHash rows from the backend are joined client-side to a card metadata catalog:

```
GET /cards/phashes  (backend API, authenticated)
        ↓ join on tcgplayer_product_id = tcgplayer_id
CATALOG_REPO/CATALOG_PATH  (external GitHub Raw, public)
        ↓
Enriched table: Product ID | Name | Set | Rarity | pHash | Source | Match status
```

- **Join key:** `tcgplayer_product_id` (phash row, INT64) = `tcgplayer_id` (catalog entry, cast to string)
- **No catalog match:** row still renders with product ID, pHash, source; catalog columns show "—" and a "no match" badge.
- **Catalog fetch failure:** if the catalog URL is unreachable the dashboard still renders with all phash data; catalog columns just show "—".

### Catalog config

The catalog repo/path is configured via env vars and injected at build time as `window.CATALOG_CONFIG`:

| Env var | `hugo.toml` key | Default |
|---------|-----------------|---------|
| `HUGO_PARAMS_CATALOG_REPO` | `params.catalog.repo` | `""` |
| `HUGO_PARAMS_CATALOG_PATH` | `params.catalog.path` | `""` |

Current catalog: `FutureGadgetCollections/collection-market-tracker-data` → `data/single-cards.json` (Riftbound cards). Add additional catalogs as needed when other game data is available.

### Stats

The summary row shows:
- **Total pHashes** — raw row count from the backend
- **Catalog Match Rate** — % of rows matched to a catalog entry
- **By Source** — count per source value

## Development Notes

- Hugo config lives in `hugo.toml`
- Firebase config goes in `.env` — never commit this file
- Environment variables are injected as `HUGO_PARAMS_*` and map to `.Site.Params.*` in templates
- The `split .Site.Params.allowed.emails ","` pattern in `head.html` converts the comma-separated email string to a JS array
- To add a new CRUD section: create `content/<section>/_index.md`, add a nav link in `navbar.html`, and optionally add `themes/admin/layouts/<section>/list.html`
- The default `list.html` provides a working CRUD template — update `RESOURCE_PATH` to your backend endpoint
- `loadJsonFromUrl(url)` in `data-loader.js` is available for fetching catalog or other external JSON without the GCS fallback logic
