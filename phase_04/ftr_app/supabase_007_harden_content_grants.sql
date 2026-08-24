-- Phase 34: least-privilege column grants for public content surfaces.
-- RLS remains enabled; this migration additionally prevents client roles from
-- selecting editorial/internal columns that are not required by the app.

revoke all privileges on table public.contents from anon, authenticated;
grant select (
  id, legacy_screen_id, slug, title, summary, content_kind, premium, status,
  source_last_reviewed_at, medical_review_status, published_at, updated_at
) on table public.contents to anon, authenticated;

revoke all privileges on table public.content_bodies from anon, authenticated;
grant select (content_id, body_html)
  on table public.content_bodies to anon, authenticated;

revoke all privileges on table public.content_assets from anon, authenticated;
grant select (
  id, content_id, asset_type, access_scope, storage_path, caption, alt_text,
  sort_order
) on table public.content_assets to anon, authenticated;

revoke all privileges on table public.content_sources from anon, authenticated;
grant select (
  content_id, title, publisher, source_url, publication_year,
  verification_status
) on table public.content_sources to anon, authenticated;

revoke all privileges on table public.content_categories from anon, authenticated;
grant select (content_id, category_id, is_primary)
  on table public.content_categories to anon, authenticated;

revoke all privileges on table public.categories from anon, authenticated;
grant select (id, slug, name, description, sort_order, is_active)
  on table public.categories to anon, authenticated;

revoke all privileges on table public.content_catalog from anon, authenticated;
grant select on table public.content_catalog to anon, authenticated;

revoke all privileges on table public.category_catalog from anon, authenticated;
grant select on table public.category_catalog to anon, authenticated;

grant execute on function public.get_content_detail(uuid) to anon, authenticated;
