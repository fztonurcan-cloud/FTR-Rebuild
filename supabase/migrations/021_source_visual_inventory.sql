create table if not exists private.source_documents (
  id uuid primary key default gen_random_uuid(),
  source_file_id text not null unique,
  source_name text not null,
  library_path text,
  source_kind text not null check (source_kind in ('ppt','pptx','pdf','image','other')),
  source_size_bytes bigint,
  source_status text not null default 'pending' check (source_status in ('pending','inventoried','mapped','complete','blocked')),
  expected_visual_count integer not null default 0 check (expected_visual_count >= 0),
  educational_visual_count integer not null default 0 check (educational_visual_count >= 0),
  mapped_visual_count integer not null default 0 check (mapped_visual_count >= 0),
  resolved_visual_count integer not null default 0 check (resolved_visual_count >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists private.source_visuals (
  id uuid primary key default gen_random_uuid(),
  source_document_id uuid not null references private.source_documents(id) on delete cascade,
  slide_page integer not null check (slide_page >= 1),
  visual_index integer not null check (visual_index >= 1),
  visual_sha256 text,
  file_extension text,
  pixel_width integer,
  pixel_height integer,
  classification text not null default 'unclear' check (classification in ('educational','decorative','duplicate','unclear')),
  rights_status text not null default 'pending' check (rights_status in ('pending','original','licensed','public_domain','cc_licensed','redraw_required')),
  target_content_id uuid references public.contents(id) on delete set null,
  placement_after_heading text,
  replacement_asset_id uuid references private.media_replacement_assets(id) on delete set null,
  resolution_status text not null default 'inventoried' check (resolution_status in ('inventoried','mapped','uploaded_review','approved','redraw_required','blocked','duplicate_linked')),
  duplicate_of_visual_id uuid references private.source_visuals(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source_document_id, slide_page, visual_index)
);

create index if not exists source_visuals_target_content_idx on private.source_visuals(target_content_id);
create index if not exists source_visuals_replacement_asset_idx on private.source_visuals(replacement_asset_id);
create index if not exists source_visuals_sha_idx on private.source_visuals(visual_sha256) where visual_sha256 is not null;
create index if not exists source_visuals_unresolved_idx on private.source_visuals(source_document_id, resolution_status, classification);

create or replace function private.guard_source_visual_approval()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  if new.resolution_status = 'approved' then
    if new.replacement_asset_id is null then
      raise exception 'SOURCE_VISUAL_APPROVAL_REQUIRES_REPLACEMENT_ASSET' using errcode='22000';
    end if;
    if not exists (
      select 1
      from private.media_replacement_assets r
      where r.id = new.replacement_asset_id
        and r.production_status = 'approved'
        and r.rights_basis in ('original','licensed','public_domain','cc_licensed')
    ) then
      raise exception 'SOURCE_VISUAL_REPLACEMENT_NOT_HUMAN_APPROVED' using errcode='22000';
    end if;
    if not exists (
      select 1
      from private.content_review_events e
      where e.event_type = 'human_media_asset_approved'
        and e.details->>'replacement_asset_id' = new.replacement_asset_id::text
    ) then
      raise exception 'SOURCE_VISUAL_HUMAN_MEDIA_EVENT_REQUIRED' using errcode='22000';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_source_visual_approval on private.source_visuals;
create trigger trg_guard_source_visual_approval
before insert or update on private.source_visuals
for each row execute function private.guard_source_visual_approval();

create or replace function private.refresh_source_document_visual_counts(p_document_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_expected integer;
  v_educational integer;
  v_mapped integer;
  v_resolved integer;
begin
  select count(*)::integer,
         count(*) filter (where classification='educational')::integer,
         count(*) filter (where classification='educational' and target_content_id is not null)::integer,
         count(*) filter (
           where classification='educational'
             and resolution_status in ('uploaded_review','approved','redraw_required','duplicate_linked')
         )::integer
  into v_expected, v_educational, v_mapped, v_resolved
  from private.source_visuals
  where source_document_id = p_document_id;

  update private.source_documents
  set expected_visual_count = coalesce(v_expected,0),
      educational_visual_count = coalesce(v_educational,0),
      mapped_visual_count = coalesce(v_mapped,0),
      resolved_visual_count = coalesce(v_resolved,0),
      source_status = case
        when coalesce(v_expected,0)=0 then 'inventoried'
        when exists (
          select 1 from private.source_visuals sv
          where sv.source_document_id=p_document_id
            and sv.classification in ('educational','unclear')
            and sv.resolution_status in ('inventoried','mapped','blocked')
        ) then 'mapped'
        when coalesce(v_educational,0) > 0 and coalesce(v_resolved,0) >= coalesce(v_educational,0) then 'complete'
        else 'inventoried'
      end,
      updated_at = now()
  where id = p_document_id;
end;
$$;

create or replace function private.on_source_visual_change_refresh_document()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.refresh_source_document_visual_counts(coalesce(new.source_document_id, old.source_document_id));
  if tg_op='UPDATE' and old.source_document_id is distinct from new.source_document_id then
    perform private.refresh_source_document_visual_counts(old.source_document_id);
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_source_visual_refresh_document on private.source_visuals;
create trigger trg_source_visual_refresh_document
after insert or update or delete on private.source_visuals
for each row execute function private.on_source_visual_change_refresh_document();

alter table private.source_documents enable row level security;
alter table private.source_visuals enable row level security;
revoke all on private.source_documents from public, anon, authenticated;
revoke all on private.source_visuals from public, anon, authenticated;
grant select, insert, update, delete on private.source_documents to service_role;
grant select, insert, update, delete on private.source_visuals to service_role;
revoke all on function private.refresh_source_document_visual_counts(uuid) from public;
grant execute on function private.refresh_source_document_visual_counts(uuid) to service_role;
