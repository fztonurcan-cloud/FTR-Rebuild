-- Phase 47: enforce premium-content redaction at the server boundary.
-- The mobile UI lock is not a security boundary; anonymous/authenticated clients
-- must never receive protected lesson bodies or protected asset paths without
-- server-maintained entitlement.

alter table public.content_bodies enable row level security;
alter table public.content_assets enable row level security;

-- Clients consume lesson detail only through get_content_detail().
revoke all privileges on table public.content_bodies from anon, authenticated;
revoke all privileges on table public.content_assets from anon, authenticated;

drop policy if exists content_bodies_read_entitled on public.content_bodies;
create policy content_bodies_read_entitled
on public.content_bodies
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.contents c
    where c.id = content_bodies.content_id
      and c.status = 'published'
      and (c.premium = false or private.has_active_entitlement())
  )
);

drop policy if exists content_assets_read_entitled on public.content_assets;
create policy content_assets_read_entitled
on public.content_assets
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.contents c
    where c.id = content_assets.content_id
      and c.status = 'published'
      and (
        content_assets.access_scope = 'preview'
        or c.premium = false
        or private.has_active_entitlement()
      )
  )
);

create or replace function public.get_content_detail(p_content_id uuid)
returns table (
  id uuid,
  slug text,
  title text,
  summary text,
  body_html text,
  content_kind text,
  premium boolean,
  has_access boolean,
  source_last_reviewed_at timestamptz,
  medical_review_status text,
  category_name text,
  category_slug text,
  sources jsonb,
  assets jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  with target as (
    select
      c.id,
      c.slug,
      c.title,
      c.summary,
      c.content_kind,
      c.premium,
      (not c.premium or private.has_active_entitlement()) as has_access,
      c.source_last_reviewed_at,
      c.medical_review_status,
      cat.name as category_name,
      cat.slug as category_slug
    from public.contents c
    left join public.content_categories cc
      on cc.content_id = c.id and cc.is_primary = true
    left join public.categories cat on cat.id = cc.category_id
    where c.id = p_content_id
      and c.status = 'published'
  )
  select
    t.id,
    t.slug,
    t.title,
    t.summary,
    case when t.has_access then b.body_html else null end as body_html,
    t.content_kind,
    t.premium,
    t.has_access,
    t.source_last_reviewed_at,
    t.medical_review_status,
    t.category_name,
    t.category_slug,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'title', s.title,
            'publisher', s.publisher,
            'source_url', s.source_url,
            'publication_year', s.publication_year,
            'verification_status', s.verification_status
          )
          order by s.publication_year desc nulls last, s.title
        )
        from public.content_sources s
        where s.content_id = t.id
          and s.verification_status = 'verified'
      ),
      '[]'::jsonb
    ) as sources,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', a.id,
            'asset_type', a.asset_type,
            'access_scope', a.access_scope,
            'storage_path', a.storage_path,
            'caption', a.caption,
            'alt_text', a.alt_text,
            'sort_order', a.sort_order
          )
          order by a.sort_order, a.id
        )
        from public.content_assets a
        where a.content_id = t.id
          and (t.has_access or a.access_scope = 'preview')
      ),
      '[]'::jsonb
    ) as assets
  from target t
  left join public.content_bodies b on b.content_id = t.id;
$$;

revoke all on function public.get_content_detail(uuid) from public;
grant execute on function public.get_content_detail(uuid) to anon, authenticated;
