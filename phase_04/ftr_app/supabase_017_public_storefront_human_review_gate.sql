-- Public storefront samples are an explicit human-curated layer.
-- This migration NEVER creates or changes any human review approval state.

create table if not exists private.storefront_samples (
  content_id uuid primary key references public.contents(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  preview_html text not null,
  source_body_sha256 text not null check (length(source_body_sha256) = 64),
  selected_by uuid not null references auth.users(id) on delete restrict,
  enabled boolean not null default false,
  selection_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(preview_html) between 40 and 8000)
);

create unique index if not exists storefront_samples_one_enabled_per_category_idx
  on private.storefront_samples(category_id)
  where enabled;

create table if not exists private.storefront_sample_assets (
  content_id uuid not null references private.storefront_samples(content_id) on delete cascade,
  asset_id uuid not null references public.content_assets(id) on delete cascade,
  sort_order smallint not null check (sort_order between 1 and 2),
  selected_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (content_id, asset_id),
  unique (content_id, sort_order)
);

alter table private.storefront_samples enable row level security;
alter table private.storefront_sample_assets enable row level security;
revoke all on private.storefront_samples from public, anon, authenticated;
revoke all on private.storefront_sample_assets from public, anon, authenticated;
grant select, insert, update, delete on private.storefront_samples to service_role;
grant select, insert, update, delete on private.storefront_sample_assets to service_role;

create or replace function private.storefront_sample_review_proof(
  p_content_id uuid,
  p_category_id uuid,
  p_preview_html text,
  p_source_body_sha256 text,
  p_selected_by uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  with body_state as (
    select
      c.id,
      c.status,
      c.premium,
      c.medical_review_status,
      c.reviewed_by,
      b.body_html,
      encode(extensions.digest(convert_to(coalesce(b.body_html, ''), 'UTF8'), 'sha256'), 'hex') as body_sha256
    from public.contents c
    join public.content_bodies b on b.content_id = c.id
    where c.id = p_content_id
  )
  select exists (
    select 1
    from body_state bs
    where bs.status = 'published'
      and bs.premium = true
      and bs.medical_review_status = 'reviewed'
      and bs.reviewed_by is not null
      and bs.body_sha256 = p_source_body_sha256
      and position(p_preview_html in bs.body_html) > 0
      and exists (
        select 1
        from public.content_categories cc
        where cc.content_id = bs.id
          and cc.category_id = p_category_id
      )
      and exists (
        select 1
        from private.content_review_events e
        where e.content_id = bs.id
          and e.event_type = 'human_medical_review_published'
          and e.actor_user_id = bs.reviewed_by
      )
      and exists (
        select 1
        from private.content_review_events e
        where e.content_id = bs.id
          and e.event_type = 'human_revision_approved'
          and e.actor_user_id is not null
          and e.details ->> 'body_sha256' = bs.body_sha256
      )
      and exists (
        select 1
        from private.reviewer_registry r
        where r.user_id = p_selected_by
          and r.active = true
          and r.can_medical_review = true
          and r.can_revision_review = true
      )
  );
$$;

revoke all on function private.storefront_sample_review_proof(uuid,uuid,text,text,uuid) from public;
grant execute on function private.storefront_sample_review_proof(uuid,uuid,text,text,uuid) to service_role;

create or replace function private.guard_storefront_sample()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.enabled and not private.storefront_sample_review_proof(
    new.content_id,
    new.category_id,
    new.preview_html,
    new.source_body_sha256,
    new.selected_by
  ) then
    raise exception 'STOREFRONT_SAMPLE_HUMAN_REVIEW_PROOF_REQUIRED' using errcode = '42501';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.guard_storefront_sample() from public;

drop trigger if exists storefront_sample_guard on private.storefront_samples;
create trigger storefront_sample_guard
before insert or update on private.storefront_samples
for each row execute function private.guard_storefront_sample();

create or replace function private.storefront_sample_is_valid(p_content_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from private.storefront_samples s
    where s.content_id = p_content_id
      and s.enabled = true
      and private.storefront_sample_review_proof(
        s.content_id,
        s.category_id,
        s.preview_html,
        s.source_body_sha256,
        s.selected_by
      )
  );
$$;

create or replace function private.storefront_preview_html(p_content_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select s.preview_html
  from private.storefront_samples s
  where s.content_id = p_content_id
    and s.enabled = true
    and private.storefront_sample_review_proof(
      s.content_id,
      s.category_id,
      s.preview_html,
      s.source_body_sha256,
      s.selected_by
    )
  limit 1;
$$;

create or replace function private.storefront_asset_review_proof(
  p_content_id uuid,
  p_asset_id uuid,
  p_selected_by uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.content_assets ca
    join private.media_replacement_assets m
      on m.content_id = ca.content_id
     and m.storage_path = ca.storage_path
    where ca.id = p_asset_id
      and ca.content_id = p_content_id
      and ca.asset_type = 'image'
      and m.production_status = 'approved'
      and m.rights_basis in ('original','licensed','public_domain','cc_licensed')
      and m.sha256 is not null
      and length(m.sha256) = 64
      and exists (
        select 1
        from private.content_review_events e
        where e.content_id = p_content_id
          and e.event_type = 'human_media_asset_approved'
          and e.actor_user_id is not null
          and e.details ->> 'content_asset_id' = ca.id::text
          and e.details ->> 'sha256' = m.sha256
      )
      and exists (
        select 1
        from private.reviewer_registry r
        where r.user_id = p_selected_by
          and r.active = true
          and r.can_media_review = true
      )
  );
$$;

revoke all on function private.storefront_asset_review_proof(uuid,uuid,uuid) from public;
grant execute on function private.storefront_asset_review_proof(uuid,uuid,uuid) to service_role;

create or replace function private.guard_storefront_sample_asset()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from private.storefront_samples s
    where s.content_id = new.content_id
      and private.storefront_sample_review_proof(
        s.content_id,
        s.category_id,
        s.preview_html,
        s.source_body_sha256,
        s.selected_by
      )
  ) then
    raise exception 'STOREFRONT_SAMPLE_CONTENT_REVIEW_PROOF_REQUIRED' using errcode = '42501';
  end if;

  if not private.storefront_asset_review_proof(new.content_id, new.asset_id, new.selected_by) then
    raise exception 'STOREFRONT_SAMPLE_MEDIA_HUMAN_REVIEW_PROOF_REQUIRED' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.guard_storefront_sample_asset() from public;

drop trigger if exists storefront_sample_asset_guard on private.storefront_sample_assets;
create trigger storefront_sample_asset_guard
before insert or update on private.storefront_sample_assets
for each row execute function private.guard_storefront_sample_asset();

create or replace function private.storefront_asset_is_valid(p_asset_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from private.storefront_sample_assets sa
    join private.storefront_samples s on s.content_id = sa.content_id
    where sa.asset_id = p_asset_id
      and private.storefront_sample_is_valid(sa.content_id)
      and private.storefront_asset_review_proof(sa.content_id, sa.asset_id, sa.selected_by)
  );
$$;

create or replace function private.can_access_storefront_media(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.content_assets ca
    where ca.storage_path = p_storage_path
      and private.storefront_asset_is_valid(ca.id)
  );
$$;

revoke all on function private.storefront_sample_is_valid(uuid) from public;
revoke all on function private.storefront_preview_html(uuid) from public;
revoke all on function private.storefront_asset_is_valid(uuid) from public;
revoke all on function private.can_access_storefront_media(text) from public;
grant execute on function private.storefront_sample_is_valid(uuid) to anon, authenticated, service_role;
grant execute on function private.storefront_preview_html(uuid) to anon, authenticated, service_role;
grant execute on function private.storefront_asset_is_valid(uuid) to anon, authenticated, service_role;
grant execute on function private.can_access_storefront_media(text) to anon, authenticated, service_role;

-- Premium preview assets are allowed only through the explicit human-reviewed storefront gate.
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
        c.premium = false
        or private.has_active_entitlement()
        or private.storefront_asset_is_valid(content_assets.id)
      )
  )
);

-- Keep internal QA access and add only human-reviewed public storefront media.
drop policy if exists ftr_content_assets_read_entitled on storage.objects;
create policy ftr_content_assets_read_entitled
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'content-assets'
  and (
    private.can_access_internal_preview_media(name)
    or private.can_access_storefront_media(name)
    or exists (
      select 1
      from public.content_assets ca
      join public.contents c on c.id = ca.content_id
      where ca.storage_path = storage.objects.name
        and c.status = 'published'
        and (c.premium = false or private.has_active_entitlement())
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
            'sort_order', a.sort_order
          ) order by a.sort_order, a.id
        )
        from public.content_assets a
        where a.content_id = t.id
          and (t.has_access or private.storefront_asset_is_valid(a.id))
      ), '[]'::jsonb
    ) as assets
  from target t
  left join public.content_bodies b on b.content_id = t.id;
$$;

revoke all on function public.get_content_detail(uuid) from public;
grant execute on function public.get_content_detail(uuid) to anon, authenticated, service_role;
