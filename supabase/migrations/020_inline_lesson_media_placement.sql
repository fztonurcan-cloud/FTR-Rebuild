-- Inline lesson media placement.
-- This stores the lesson heading after which an instructional image belongs.
-- Human media approval remains mandatory and is not bypassed.

alter table public.content_assets
  add column if not exists placement_after_heading text;

alter table private.media_replacement_assets
  add column if not exists placement_after_heading text;

alter table public.content_assets
  drop constraint if exists content_assets_placement_after_heading_check;
alter table public.content_assets
  add constraint content_assets_placement_after_heading_check
  check (placement_after_heading is null or char_length(placement_after_heading) <= 240);

alter table private.media_replacement_assets
  drop constraint if exists media_replacement_assets_placement_after_heading_check;
alter table private.media_replacement_assets
  add constraint media_replacement_assets_placement_after_heading_check
  check (placement_after_heading is null or char_length(placement_after_heading) <= 240);

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
as $function$
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
          and (t.has_access or private.storefront_asset_is_valid(a.id))
      ), '[]'::jsonb
    ) as assets
  from target t
  left join public.content_bodies b on b.content_id = t.id;
$function$;

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
as $function$
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
$function$;

create or replace function public.approve_media_asset(
  p_replacement_asset_id uuid,
  p_notes text default null::text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid;
  r private.media_replacement_assets%rowtype;
  v_content_asset_id uuid;
  v_required integer := 0;
  v_approved integer := 0;
begin
  v_uid := private.require_reviewer_permission('media');

  select * into r
  from private.media_replacement_assets
  where id = p_replacement_asset_id
  for update;

  if not found then
    raise exception 'MEDIA_ASSET_NOT_FOUND' using errcode='P0002';
  end if;
  if r.production_status <> 'review' then
    raise exception 'MEDIA_ASSET_NOT_READY:%', r.production_status using errcode='22000';
  end if;
  if r.rights_basis not in ('original','licensed','public_domain','cc_licensed') then
    raise exception 'MEDIA_RIGHTS_NOT_CLEARED' using errcode='22000';
  end if;
  if nullif(btrim(coalesce(r.storage_path,'')),'') is null
     or r.sha256 is null
     or length(r.sha256) <> 64 then
    raise exception 'MEDIA_INTEGRITY_INCOMPLETE' using errcode='22000';
  end if;
  if not exists(
    select 1
    from storage.objects o
    where o.bucket_id='content-assets'
      and o.name=r.storage_path
      and coalesce(nullif(o.metadata->>'size','')::bigint,0)>0
  ) then
    raise exception 'MEDIA_STORAGE_OBJECT_MISSING' using errcode='P0002';
  end if;

  update private.media_replacement_assets
  set production_status='approved',
      notes=concat_ws(E'\n', nullif(notes,''), nullif(btrim(coalesce(p_notes,'')),'')),
      updated_at=now()
  where id=r.id;

  select a.id into v_content_asset_id
  from public.content_assets a
  where a.storage_path=r.storage_path
  limit 1;

  if v_content_asset_id is null then
    insert into public.content_assets(
      content_id, asset_type, access_scope, storage_path,
      caption, alt_text, sort_order, placement_after_heading
    ) values(
      r.content_id, 'image', 'protected', r.storage_path,
      nullif(btrim(coalesce(r.concept,'')),''), r.alt_text, 0,
      r.placement_after_heading
    )
    returning id into v_content_asset_id;
  else
    update public.content_assets
    set content_id=r.content_id,
        asset_type='image',
        access_scope='protected',
        caption=coalesce(nullif(btrim(coalesce(r.concept,'')),''), caption),
        alt_text=coalesce(r.alt_text,alt_text),
        placement_after_heading=coalesce(r.placement_after_heading,placement_after_heading)
    where id=v_content_asset_id;
  end if;

  select coalesce(p.required_asset_count,0)
  into v_required
  from private.content_media_plans p
  where p.content_id=r.content_id;

  select count(*)::integer
  into v_approved
  from private.media_replacement_assets a
  where a.content_id=r.content_id
    and a.production_status='approved'
    and a.rights_basis in ('original','licensed','public_domain','cc_licensed')
    and nullif(btrim(coalesce(a.storage_path,'')),'') is not null
    and a.sha256 is not null;

  if v_approved >= v_required then
    update private.content_media_plans
    set plan_status='approved', updated_at=now()
    where content_id=r.content_id
      and plan_status<>'not_needed';
  end if;

  insert into private.content_review_events(
    content_id, actor_user_id, event_type, details
  ) values(
    r.content_id,
    v_uid,
    'human_media_asset_approved',
    jsonb_build_object(
      'replacement_asset_id',r.id,
      'content_asset_id',v_content_asset_id,
      'sha256',r.sha256,
      'placement_after_heading',r.placement_after_heading
    )
  );

  return jsonb_build_object(
    'ok',true,
    'content_id',r.content_id,
    'replacement_asset_id',r.id,
    'content_asset_id',v_content_asset_id,
    'approved_assets',v_approved,
    'required_assets',v_required
  );
end;
$function$;

create or replace function public.service_promote_media_asset(
  p_replacement_asset_id uuid,
  p_access_scope text default 'protected'::text,
  p_caption text default null::text,
  p_alt_text text default null::text,
  p_sort_order integer default 0
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  r private.media_replacement_assets%rowtype;
  v_content_asset_id uuid;
begin
  if p_access_scope not in ('preview', 'protected') then
    raise exception 'invalid_access_scope' using errcode = '22023';
  end if;

  select * into r
  from private.media_replacement_assets
  where id = p_replacement_asset_id
  for update;

  if not found then
    raise exception 'replacement_asset_not_found' using errcode = 'P0002';
  end if;
  if r.production_status <> 'approved' then
    raise exception 'asset_not_approved' using errcode = '22000';
  end if;
  if r.rights_basis = 'pending' then
    raise exception 'rights_basis_pending' using errcode = '22000';
  end if;
  if r.storage_path is null or btrim(r.storage_path) = '' then
    raise exception 'asset_not_uploaded' using errcode = '22000';
  end if;
  if r.sha256 is null or length(r.sha256) <> 64 then
    raise exception 'asset_sha_missing' using errcode = '22000';
  end if;

  if not exists (
    select 1
    from storage.objects
    where bucket_id = 'content-assets'
      and name = r.storage_path
  ) then
    raise exception 'storage_object_not_found' using errcode = 'P0002';
  end if;

  select id into v_content_asset_id
  from public.content_assets
  where storage_path = r.storage_path
  limit 1;

  if v_content_asset_id is null then
    insert into public.content_assets (
      content_id, asset_type, access_scope, storage_path,
      caption, alt_text, sort_order, placement_after_heading
    ) values (
      r.content_id, 'image', p_access_scope, r.storage_path,
      coalesce(p_caption, nullif(btrim(coalesce(r.concept,'')),'')),
      coalesce(p_alt_text, r.alt_text),
      greatest(p_sort_order, 0),
      r.placement_after_heading
    )
    returning id into v_content_asset_id;
  else
    update public.content_assets
    set content_id = r.content_id,
        asset_type = 'image',
        access_scope = p_access_scope,
        caption = coalesce(p_caption, nullif(btrim(coalesce(r.concept,'')),''), caption),
        alt_text = coalesce(p_alt_text, r.alt_text, alt_text),
        sort_order = greatest(p_sort_order, 0),
        placement_after_heading = coalesce(r.placement_after_heading, placement_after_heading)
    where id = v_content_asset_id;
  end if;

  return v_content_asset_id;
end;
$function$;
