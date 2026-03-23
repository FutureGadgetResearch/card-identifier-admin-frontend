-- BigQuery table: card_phashes
-- Project: future-gadget-labs-483502
-- Dataset: card_identifier
--
-- phash is stored as INT64 (signed). All 64-bit phash libraries produce
-- unsigned values; cast to signed on insert (bit pattern is identical).
-- Export queries should CAST(phash AS STRING) to avoid JSON precision loss
-- for values > 2^53.

CREATE TABLE IF NOT EXISTS `future-gadget-labs-483502.card_identifier.card_phashes` (
  row_id     STRING    NOT NULL OPTIONS(description="UUID set by backend on insert"),
  card_id    STRING    NOT NULL OPTIONS(description="Canonical card identifier, e.g. SV01-001"),
  phash      INT64     NOT NULL OPTIONS(description="64-bit perceptual hash stored as signed integer"),
  source     STRING    NOT NULL OPTIONS(description="tcgplayer | my_scan | penny_sleeve | top_loader"),
  image_url  STRING             OPTIONS(description="Back-reference URL to source image"),
  created_at TIMESTAMP NOT NULL
)
OPTIONS(
  description="Card perceptual hash mappings for image-based card identification"
);
