-- Phase 34: trusted media upload + promotion gates.
-- Binary uploads happen only from a trusted maintainer/CI environment.
-- These RPCs are callable only by service_role and never from the Flutter app.

create unique index if not exists content_assets_storage_path_uidx
  on public.content_assets (storage_path);

create or replace function public.service_register_media_upload(
  p_replacement_asset_id uuid,
  p_storage_path text,
  p_sha256 text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  r private.media_replacement_assets%rowtype;
  obj storage.objects%rowtype;
  expected_prefix text;
  object_size bigint;
  object_mime text;
begin
  if p_storage_path is null or btrim(p_storage_path) = '' then
    raise exception 'storage_path_required' using errcode = '22023';
  end if;
  if p_sha256 is null or length(btrim(p_sha256)) <> 64 then
    raise exception 'valid_sha256_required' using errcode = '22023';
  end if;
  if left(p_storage_path, 1) = '/' or position('..' in p_storage_path) > 0 then
    raise exception 'invalid_storage_path' using errcode = '22023';
  end if;

  select * into r
  from private.media_replacement_assets
  where id = p_replacement_asset_id
  for update;

  if not found then
    raise exception 'replacement_asset_not_found' using errcode = 'P0002';
  end if;
  if r.sha256 is null or lower(r.sha256) <> lower(btrim(p_sha256)) then
    raise exception 'sha256_mismatch' using errcode = '22000';
  end if;
  if r.rights_basis = 'pending' then
    raise exception 'rights_basis_pending' using errcode = '22000';
  end if;
  if r.production_status not in ('generated', 'designed', 'review', 'approved') then
    raise exception 'asset_not_uploadable_in_status:%', r.production_status using errcode = '22000';
  end if;

  expected_prefix := 'replacements/' || r.content_id::text || '/' || r.id::text || '/';
  if left(p_storage_path, length(expected_prefix)) <> expected_prefix then
    raise exception 'storage_path_not_bound_to_asset' using errcode = '22000';
  end if;

  select * into obj
  from storage.objects
  where bucket_id = 'content-assets'
    and name = p_storage_path
  limit 1;
  if not found then
    raise exception 'storage_object_not_found' using errcode = 'P0002';
  end if;

  object_size := nullif(obj.metadata->>'size', '')::bigint;
  object_mime := lower(coalesce(obj.metadata->>'mimetype', ''));
  if coalesce(object_size, 0) <= 0 then
    raise exception 'storage_object_empty' using errcode = '22000';
  end if;
  if object_mime not in ('image/png', 'image/jpeg', 'image/webp', 'video/mp4') then
    raise exception 'unsupported_storage_mime:%', object_mime using errcode = '22000';
  end if;

  update private.media_replacement_assets
  set storage_path = p_storage_path,
      production_status = case
        when production_status in ('generated', 'designed') then 'review'
        else production_status
      end,
      updated_at = now()
  where id = r.id;

  return jsonb_build_object(
    'replacement_asset_id', r.id,
    'content_id', r.content_id,
    'storage_path', p_storage_path,
    'sha256', lower(btrim(p_sha256)),
    'size', object_size,
    'mimetype', object_mime,
    'status', case
      when r.production_status in ('generated', 'designed') then 'review'
      else r.production_status
    end
  );
end;
$$;

revoke all on function public.service_register_media_upload(uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.service_register_media_upload(uuid, text, text)
  to service_role;

create or replace function public.service_promote_media_asset(
  p_replacement_asset_id uuid,
  p_access_scope text default 'protected',
  p_caption text default null,
  p_alt_text text default null,
  p_sort_order integer default 0
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  r private.media_replacement_assets%rowtype;
  v_asset_type text;
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

  v_asset_type := case when r.asset_kind = 'video' then 'video' else 'image' end;

  select id into v_content_asset_id
  from public.content_assets
  where storage_path = r.storage_path
  limit 1;

  if v_content_asset_id is null then
    insert into public.content_assets (
      content_id, asset_type, access_scope, storage_path, caption, alt_text,
      sort_order
    ) values (
      r.content_id, v_asset_type, p_access_scope, r.storage_path, p_caption,
      coalesce(p_alt_text, r.alt_text), greatest(p_sort_order, 0)
    )
    returning id into v_content_asset_id;
  else
    update public.content_assets
    set content_id = r.content_id,
        asset_type = v_asset_type,
        access_scope = p_access_scope,
        caption = coalesce(p_caption, caption),
        alt_text = coalesce(p_alt_text, r.alt_text, alt_text),
        sort_order = greatest(p_sort_order, 0)
    where id = v_content_asset_id;
  end if;

  return v_content_asset_id;
end;
$$;

revoke all on function public.service_promote_media_asset(uuid, text, text, text, integer)
  from public, anon, authenticated;
grant execute on function public.service_promote_media_asset(uuid, text, text, text, integer)
  to service_role;
