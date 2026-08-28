-- Product decision: FTR Akademi will not ship video media.
-- Lessons use integrated text + images; video is intentionally removed from
-- both public content assets and the trusted replacement media pipeline.

alter table public.content_assets
  drop constraint if exists content_assets_asset_type_check;

alter table public.content_assets
  add constraint content_assets_asset_type_check
  check (asset_type = any (array['image'::text, 'pdf'::text, 'file'::text]));

alter table private.media_replacement_assets
  drop constraint if exists media_replacement_assets_asset_kind_check;

alter table private.media_replacement_assets
  add constraint media_replacement_assets_asset_kind_check
  check (asset_kind = any (array[
    'diagram'::text,
    'illustration'::text,
    'exercise_sequence'::text,
    'photo'::text,
    'table'::text,
    'icon'::text
  ]));
