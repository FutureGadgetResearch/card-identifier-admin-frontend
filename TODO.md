# Card Identifier — Work Tracker

Scope: the full four-repo suite (`card-identifier-admin-frontend`, `card-identifier-backend`, `card-identifier-data`, `card-identifier-frontend`).

Tell Claude: *"work on the next TODO item"* and it will pick the top unchecked item, do the work, then move it to Done.

---

## Up Next

- [x] **Switch p-hash table key to TCGPlayer product ID** — BQ table recreated with `tcgplayer_product_id` (INT64, REQUIRED). Backend model, bq client, and handlers updated. Frontend CRUD and dashboard updated. No data migration needed (table was empty).

- [ ] **Local CLI: bulk p-hash ingestion from stock photo folder** — Go script in `card-identifier-backend` that walks a local `tcg_stock_photos/` folder, treats each filename (minus extension) as a `tcgplayer_product_id`, computes a 64-bit pHash, and upserts into `card_phashes` with `source='tcgplayer'`. Upsert logic: overwrite the existing row if one already exists for `(tcgplayer_product_id, source='tcgplayer')`, otherwise insert. Depends on the TCGPlayer product ID migration above being done first.

---

## Done

- [x] **Fix Google sign-in on the admin frontend** — Root cause: `futuregadgetresearch.github.io` was missing from Firebase authorized domains in `collection-showcase-auth` project. Added via Identity Platform API. Firebase config written to `.env` (gitignored) for local dev. GitHub Actions secrets/variables still need to be set (see below).
- [x] **Dashboard page** — Read-only enriched view of live pHash data at `/dashboard/`. Fetches `GET /cards/phashes` from backend and joins client-side to `single-cards.json` catalog on `tcgplayer_product_id = tcgplayer_id`. Gracefully degrades for legacy `card_id` rows (pre-migration) and catalog fetch failures. Stats row, search/filter bar, and match-rate indicator included. Match rate shows "N/A" until the product ID migration (next TODO) is done.

