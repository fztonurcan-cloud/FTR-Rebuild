-- Quality gate: keep generated drafts for audit/review, but do not expose them
-- in student or internal QA lesson rendering until explicitly replaced by
-- source-derived or high-quality reviewed media.

create table if not exists private.media_quality_blocks (
  storage_path text primary key,
  reason text not null,
  blocked_at timestamptz not null default now()
);

alter table private.media_quality_blocks enable row level security;
revoke all on private.media_quality_blocks from public, anon, authenticated;
grant all on private.media_quality_blocks to service_role;

insert into private.media_quality_blocks(storage_path, reason)
select distinct r.storage_path,
       case
         when r.storage_path like '%/auto-topic-summary.png' then 'low_quality_auto_topic_summary'
         when lower(coalesce(r.notes,'')) like '%server-generated%' then 'legacy_server_generated_draft'
         else 'automated_generated_draft'
       end
from private.media_replacement_assets r
where nullif(btrim(coalesce(r.storage_path,'')), '') is not null
  and (
    r.storage_path like '%/auto-topic-summary.png'
    or lower(coalesce(r.notes,'')) like '%server-generated%'
    or lower(coalesce(r.notes,'')) like '%otomatik özgün konu infografiği üretildi%'
  )
on conflict (storage_path) do update
set reason = excluded.reason,
    blocked_at = now();

insert into private.media_quality_blocks(storage_path, reason)
select distinct a.storage_path, 'legacy_generated_collection'
from public.content_assets a
where a.asset_type = 'image'
  and (
    a.storage_path like 'anatomy_core_2026/%'
    or a.storage_path like 'patoloji_fizyopatoloji_2026/%'
    or a.storage_path like 'biyokimya_2026/%'
    or a.storage_path like 'etik_ftr_2026/%'
    or a.storage_path like 'iih2026/%'
    or a.storage_path like 'psikoloji_sosyoloji_2026/%'
    or a.storage_path like 'tibbi_biyoloji_genetik_2026/%'
  )
on conflict (storage_path) do update
set reason = excluded.reason,
    blocked_at = now();

create or replace function private.media_is_student_displayable(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select nullif(btrim(coalesce(p_storage_path, '')), '') is not null
     and not exists (
       select 1
       from private.media_quality_blocks b
       where b.storage_path = p_storage_path
     );
$$;

revoke all on function private.media_is_student_displayable(text) from public;
grant execute on function private.media_is_student_displayable(text) to anon, authenticated, service_role;

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
            'sort_order', a.sort_order,
            'placement_after_heading', a.placement_after_heading
          ) as asset
        from public.content_assets a
        where a.content_id = t.id
          and private.media_is_student_displayable(a.storage_path)

        union all

        select
          r.id as asset_id,
          1000 + row_number() over (order by r.created_at, r.id)::integer as sort_order,
          jsonb_build_object(
            'id', r.id,
            'asset_type', 'image',
            'access_scope', 'internal_review',
            'storage_path', r.storage_path,
            'caption', nullif(btrim(coalesce(r.concept, '')), ''),
            'alt_text', r.alt_text,
            'sort_order', 1000 + row_number() over (order by r.created_at, r.id)::integer,
            'placement_after_heading', r.placement_after_heading
          ) as asset
        from private.media_replacement_assets r
        where r.content_id = t.id
          and r.production_status = 'review'
          and r.rights_basis in ('original', 'licensed', 'public_domain', 'cc_licensed')
          and nullif(btrim(coalesce(r.storage_path, '')), '') is not null
          and r.sha256 is not null
          and length(r.sha256) = 64
          and private.media_is_student_displayable(r.storage_path)
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

create or replace function public.get_content_detail(p_content_id uuid)
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
language sql
stable
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
      private.storefront_preview_html(c.id) as storefront_preview_html,
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
    case
      when t.has_access then b.body_html
      else t.storefront_preview_html
    end as body_html,
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
          ) order by s.publication_year desc nulls last, s.title
        )
        from public.content_sources s
        where s.content_id = t.id
          and s.verification_status = 'verified'
      ), '[]'::jsonb
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
            'sort_order', a.sort_order,
            'placement_after_heading', a.placement_after_heading
          ) order by a.sort_order, a.id
        )
        from public.content_assets a
        where a.content_id = t.id
          and private.media_is_student_displayable(a.storage_path)
          and (t.has_access or private.storefront_asset_is_valid(a.id))
      ), '[]'::jsonb
    ) as assets
  from target t
  left join public.content_bodies b on b.content_id = t.id;
$$;
