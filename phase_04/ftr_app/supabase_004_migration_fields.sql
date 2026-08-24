-- Migration-only provenance fields. These are never exposed through content_catalog.
alter table public.contents add column if not exists legacy_updated_at timestamptz;
alter table public.contents add column if not exists legacy_parent_sections text[] not null default '{}';
alter table public.contents add column if not exists legacy_body_html text;

comment on column public.contents.legacy_body_html is 'Raw unsanitized HTML recovered from the old APK. Never render directly; migrate into body_html only after sanitization and clinical review.';
