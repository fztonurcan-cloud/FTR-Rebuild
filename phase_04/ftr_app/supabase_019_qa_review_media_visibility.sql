-- QA-only visibility for staged media.
-- This migration does NOT approve media, publish content, or bypass human review.

create or replace function private.can_access_internal_preview_media(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_internal_preview_tester()
     and (
       exists (
         select 1
         from public.content_assets ca
         join public.contents c on c.id = ca.content_id
         where ca.storage_path = p_storage_path
           and c.status in ('review', 'published')
       )
       or exists (
         select 1
         from private.media_replacement_assets r
         join public.contents c on c.id = r.content_id
         where r.storage_path = p_storage_path
           and c.status in ('review', 'published')
           and r.production_status = 'review'
           and r.rights_basis in ('original', 'licensed', 'public_domain', 'cc_licensed')
           and r.sha256 is not null
           and length(r.sha256) = 64
       )
     );
$$;

create or replace function public.internal_preview_content_detail(p_content_id uuid)
returns table(
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
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_internal_preview_tester() then
    raise exception 'internal_preview_not_allowed' using errcode = '42501';
  end if;

  return query
  with target as (
    select
      c.id, c.slug, c.title, c.summary, b.body_html, c.content_kind,
      c.premium, c.source_last_reviewed_at, c.medical_review_status,
      cat.name as category_name, cat.slug as category_slug
    from public.contents c
    left join public.content_bodies b on b.content_id = c.id
    left join public.content_categories cc on cc.content_id = c.id and cc.is_primary
    left join public.categories cat on cat.id = cc.category_id
    where c.id = p_content_id
      and c.status in ('review', 'published')
  )
  select
    t.id, t.slug, t.title, t.summary, t.body_html, t.content_kind,
    t.premium, true as has_access, t.source_last_reviewed_at,
    t.medical_review_status, t.category_name, t.category_slug,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'title', s.title,
        'publisher', s.publisher,
        'source_url', s.source_url,
        'publication_year', s.publication_year,
        'verification_status', s.verification_status
      ) order by s.publication_year desc nulls last, s.title)
      from public.content_sources s
      where s.content_id = t.id
    ), '[]'::jsonb) as sources,
    coalesce((
      select jsonb_agg(x.asset order by x.sort_order, x.asset_id)
      from (
        select
          a.id as asset_id,
          a.sort_order,
          jsonb_build_object(
            'id', a.id,
            'asset_type', a.asset_type,
            'access_scope', a.access_scope,
            'storage_path', a.storage_path,
            'caption', a.caption,
            'alt_text', a.alt_text,
            'sort_order', a.sort_order
          ) as asset
        from public.content_assets a
        where a.content_id = t.id

        union all

        select
          r.id as asset_id,
          1000 + row_number() over (order by r.created_at, r.id)::integer as sort_order,
          jsonb_build_object(
            'id', r.id,
            'asset_type', case when r.asset_kind = 'video' then 'video' else 'image' end,
            'access_scope', 'internal_review',
            'storage_path', r.storage_path,
            'caption', nullif(btrim(coalesce(r.concept, '')), ''),
            'alt_text', r.alt_text,
            'sort_order', 1000 + row_number() over (order by r.created_at, r.id)::integer
          ) as asset
        from private.media_replacement_assets r
        where r.content_id = t.id
          and r.production_status = 'review'
          and r.rights_basis in ('original', 'licensed', 'public_domain', 'cc_licensed')
          and nullif(btrim(coalesce(r.storage_path, '')), '') is not null
          and r.sha256 is not null
          and length(r.sha256) = 64
          and exists (
            select 1
            from storage.objects o
            where o.bucket_id = 'content-assets'
              and o.name = r.storage_path
          )
          and not exists (
            select 1
            from public.content_assets a
            where a.storage_path = r.storage_path
          )
      ) x
    ), '[]'::jsonb) as assets
  from target t;
end;
$$;

revoke all on function public.internal_preview_content_detail(uuid) from public, anon, authenticated;
grant execute on function public.internal_preview_content_detail(uuid) to service_role;
