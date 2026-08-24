create or replace function public.service_register_brief_server_generated_diagram(
  p_replacement_asset_id uuid,
  p_storage_path text,
  p_sha256 text,
  p_generation_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
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
  if p_sha256 is null or length(btrim(p_sha256)) <> 64 or btrim(p_sha256) !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'valid_sha256_required' using errcode = '22023';
  end if;
  if left(p_storage_path, 1) = '/' or position('..' in p_storage_path) > 0 then
    raise exception 'invalid_storage_path' using errcode = '22023';
  end if;

  select * into r
  from private.media_replacement_assets
  where id = p_replacement_asset_id
  for update;

  if not found then raise exception 'replacement_asset_not_found' using errcode = 'P0002'; end if;
  if r.rights_basis <> 'original' then raise exception 'server_generation_requires_original_rights_basis' using errcode = '22000'; end if;
  if r.production_status <> 'brief' then raise exception 'asset_not_brief:%', r.production_status using errcode = '22000'; end if;
  if r.asset_kind <> 'diagram' then raise exception 'only_diagram_assets_allowed:%', r.asset_kind using errcode = '22000'; end if;
  if r.storage_path is not null then raise exception 'asset_already_has_storage_path' using errcode = '22000'; end if;

  expected_prefix := 'replacements/' || r.content_id::text || '/' || r.id::text || '/';
  if left(p_storage_path, length(expected_prefix)) <> expected_prefix then
    raise exception 'storage_path_not_bound_to_asset' using errcode = '22000';
  end if;

  select * into obj from storage.objects
  where bucket_id = 'content-assets' and name = p_storage_path limit 1;
  if not found then raise exception 'storage_object_not_found' using errcode = 'P0002'; end if;

  object_size := nullif(obj.metadata->>'size', '')::bigint;
  object_mime := lower(coalesce(obj.metadata->>'mimetype', ''));
  if coalesce(object_size, 0) <= 0 then raise exception 'storage_object_empty' using errcode = '22000'; end if;
  if object_mime not in ('image/png', 'image/jpeg', 'image/webp') then
    raise exception 'unsupported_storage_mime:%', object_mime using errcode = '22000';
  end if;

  update private.media_replacement_assets
  set sha256 = lower(btrim(p_sha256)),
      storage_path = p_storage_path,
      production_status = 'review',
      notes = case when nullif(btrim(coalesce(p_generation_note, '')), '') is null then notes
                   else coalesce(notes, '') || E'\n' || btrim(p_generation_note) end,
      updated_at = now()
  where id = r.id;

  return jsonb_build_object('replacement_asset_id',r.id,'content_id',r.content_id,
    'storage_path',p_storage_path,'sha256',lower(btrim(p_sha256)),'size',object_size,
    'mimetype',object_mime,'status','review');
end;
$function$;

revoke all on function public.service_register_brief_server_generated_diagram(uuid,text,text,text) from public, anon, authenticated;
grant execute on function public.service_register_brief_server_generated_diagram(uuid,text,text,text) to service_role, postgres;

create or replace function public.service_register_brief_server_generated_diagram_batch(
  p_items jsonb,
  p_generation_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  item jsonb;
  results jsonb := '[]'::jsonb;
  item_result jsonb;
  item_count integer;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'items_array_required' using errcode = '22023';
  end if;
  item_count := jsonb_array_length(p_items);
  if item_count < 1 or item_count > 20 then
    raise exception 'items_count_out_of_range:%', item_count using errcode = '22023';
  end if;

  for item in select value from jsonb_array_elements(p_items)
  loop
    if nullif(item->>'replacement_asset_id', '') is null
       or nullif(item->>'storage_path', '') is null
       or nullif(item->>'sha256', '') is null then
      raise exception 'item_fields_required' using errcode = '22023';
    end if;
    item_result := public.service_register_brief_server_generated_diagram(
      (item->>'replacement_asset_id')::uuid,
      item->>'storage_path', item->>'sha256', p_generation_note);
    results := results || jsonb_build_array(item_result);
  end loop;
  return jsonb_build_object('ok',true,'count',item_count,'results',results);
end;
$function$;

revoke all on function public.service_register_brief_server_generated_diagram_batch(jsonb,text) from public, anon, authenticated;
grant execute on function public.service_register_brief_server_generated_diagram_batch(jsonb,text) to service_role, postgres;
