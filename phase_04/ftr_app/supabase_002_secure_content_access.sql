-- FTR phase 03 security hardening
-- Base tables containing full lesson bodies/assets are not client-readable.
revoke select on public.contents from anon, authenticated;
revoke select on public.content_assets from anon, authenticated;

-- Safe public catalog. This view intentionally exposes metadata only.
create or replace view public.content_catalog as
select
  c.id, c.legacy_screen_id, c.slug, c.title, c.summary, c.content_kind, c.premium,
  c.medical_review_status, c.source_last_reviewed_at, c.published_at, c.updated_at,
  cat.name as category_name
from public.contents c
left join public.content_categories cc
  on cc.content_id = c.id and cc.is_primary = true
left join public.categories cat on cat.id = cc.category_id
where c.status = 'published';

grant select on public.content_catalog to anon, authenticated;

-- Full body is returned only for free items or users whose server-maintained
-- subscription is active/grace. Purchase verification must update subscriptions
-- from a trusted backend/Edge Function, never directly from the mobile client.
create or replace function public.get_content_detail(p_content_id uuid)
returns table (
  id uuid,
  slug text,
  title text,
  summary text,
  body_html text,
  content_kind text,
  premium boolean,
  source_last_reviewed_at timestamptz,
  medical_review_status text,
  category_name text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id, c.slug, c.title, c.summary, c.body_html, c.content_kind, c.premium,
    c.source_last_reviewed_at, c.medical_review_status, cat.name
  from public.contents c
  left join public.content_categories cc
    on cc.content_id = c.id and cc.is_primary = true
  left join public.categories cat on cat.id = cc.category_id
  where c.id = p_content_id
    and c.status = 'published'
    and (
      c.premium = false
      or exists (
        select 1
        from public.subscriptions s
        where s.user_id = auth.uid()
          and s.status in ('active', 'grace')
          and (s.expires_at is null or s.expires_at > now())
      )
    );
$$;

revoke all on function public.get_content_detail(uuid) from public;
grant execute on function public.get_content_detail(uuid) to anon, authenticated;

-- Premium media/PDFs must be served using short-lived signed URLs after the
-- same server-side entitlement check. Do not make the premium storage bucket public.
