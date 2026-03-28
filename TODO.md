# Card Identifier — Work Tracker

Scope: the full four-repo suite (`card-identifier-admin-frontend`, `card-identifier-backend`, `card-identifier-data`, `card-identifier-frontend`).

Tell Claude: *"work on the next TODO item"* and it will pick the top unchecked item, do the work, then move it to Done.

---

## Up Next

- [x] **Switch p-hash table key to TCGPlayer product ID** — BQ table recreated with `tcgplayer_product_id` (INT64, REQUIRED). Backend model, bq client, and handlers updated. Frontend CRUD and dashboard updated. No data migration needed (table was empty).

- [x] **Ingest TCGPlayer stock images via UI** — Replaces the local CLI approach. Backend `POST /cards/phashes/ingest` accepts `{ tcgplayer_product_ids: [int64] }`, fetches each stock image from TCGPlayer's public CDN, computes a 64-bit DCT pHash via `goimagehash`, and upserts into `card_phashes` with `source='tcgplayer'`. Frontend "Ingest" button on the Cards page opens a modal with a textarea for product IDs; shows per-ID success/error results.

---

## Done

- [x] **Fix Google sign-in on the admin frontend** — Root cause: `futuregadgetresearch.github.io` was missing from Firebase authorized domains in `collection-showcase-auth` project. Added via Identity Platform API. Firebase config written to `.env` (gitignored) for local dev. GitHub Actions secrets/variables still need to be set (see below).
- [x] **Dashboard page** — Read-only enriched view of live pHash data at `/dashboard/`. Fetches `GET /cards/phashes` from backend and joins client-side to `single-cards.json` catalog on `tcgplayer_product_id = tcgplayer_id`. Gracefully degrades for legacy `card_id` rows (pre-migration) and catalog fetch failures. Stats row, search/filter bar, and match-rate indicator included. Match rate shows "N/A" until the product ID migration (next TODO) is done.

