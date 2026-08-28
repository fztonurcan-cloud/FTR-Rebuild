-- Phase 60: internal device QA preview.
-- This migration creates no tester identities and grants no reviewer authority.
-- Human medical/editorial/media review state remains authoritative for production.

create table if not exists private.preview_tester_registry (
  user_id uuid primary key references auth.users(id) on delete cascade,
  enabled boolean not null default true,
  purpose text not null default 'internal_device_preview',
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

alter table private.preview_tester_registry enable row level security;
revoke all on table private.preview_tester_registry from public, anon, authenticated, service_role;

create or replace function private.is_internal_preview_tester()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
     and exists (
       select 1
       from private.preview_tester_registry r
       where r.user_id = auth.uid()
         and r.enabled
         and (r.expires_at is null or r.expires_at > now())
     );
$$;

create or replace function private.set_internal_preview_claims(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_user_id is null or not exists (
    select 1
    from private.preview_tester_registry r
    where r.user_id = p_user_id
      and r.enabled
      and (r.expires_at is null or r.expires_at > now())
  ) then
    raise exception 'internal_preview_not_allowed' using errcode = '42501';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', p_user_id, 'role', 'authenticated')::text,
    true
  );
end;
$$;

create or replace function private.can_access_internal_preview_media(p_storage_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_internal_preview_tester()
     and exists (
       select 1
       from public.content_assets ca
       join public.contents c on c.id = ca.content_id
       where ca.storage_path = p_storage_path
         and c.status in ('review', 'published')
     );
$$;

create or replace function public.internal_preview_categories()
returns table(
  id uuid,
  slug text,
  name text,
  description text,
  sort_order integer,
  content_count integer
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
  select
    cat.id,
    cat.slug,
    cat.name,
    cat.description,
    cat.sort_order,
    count(distinct c.id)::integer as content_count
  from public.categories cat
  left join public.content_categories cc on cc.category_id = cat.id
  left join public.contents c
    on c.id = cc.content_id
   and c.status in ('review', 'published')
  where cat.is_active
  group by cat.id, cat.slug, cat.name, cat.description, cat.sort_order
  order by cat.sort_order, cat.name;
end;
$$;

create or replace function public.internal_preview_featured_contents(p_limit integer default 10)
returns table(
  id uuid,
  legacy_screen_id text,
  slug text,
  title text,
  summary text,
  content_kind text,
  premium boolean,
  medical_review_status text,
  source_last_reviewed_at timestamptz,
  published_at timestamptz,
  updated_at timestamptz,
  category_name text,
  category_slug text
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
  if p_limit < 1 or p_limit > 100 then
    raise exception 'invalid_limit' using errcode = '22023';
  end if;

  return query
  select
    c.id, c.legacy_screen_id, c.slug, c.title, c.summary, c.content_kind,
    c.premium, c.medical_review_status, c.source_last_reviewed_at,
    c.published_at, c.updated_at, cat.name, cat.slug
  from public.contents c
  left join public.content_categories cc on cc.content_id = c.id and cc.is_primary
  left join public.categories cat on cat.id = cc.category_id
  where c.status in ('review', 'published')
  order by c.updated_at desc, c.title, c.id
  limit p_limit;
end;
$$;

create or replace function public.internal_preview_category_contents(
  p_category_name text,
  p_offset integer default 0,
  p_limit integer default 50
)
returns table(
  id uuid,
  legacy_screen_id text,
  slug text,
  title text,
  summary text,
  content_kind text,
  premium boolean,
  medical_review_status text,
  source_last_reviewed_at timestamptz,
  published_at timestamptz,
  updated_at timestamptz,
  category_name text,
  category_slug text
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
  if nullif(btrim(coalesce(p_category_name, '')), '') is null then
    raise exception 'category_name_required' using errcode = '22023';
  end if;
  if p_offset < 0 or p_limit < 1 or p_limit > 100 then
    raise exception 'invalid_pagination' using errcode = '22023';
  end if;

  return query
  select
    c.id, c.legacy_screen_id, c.slug, c.title, c.summary, c.content_kind,
    c.premium, c.medical_review_status, c.source_last_reviewed_at,
    c.published_at, c.updated_at, cat.name, cat.slug
  from public.contents c
  join public.content_categories cc on cc.content_id = c.id and cc.is_primary
  join public.categories cat on cat.id = cc.category_id
  where c.status in ('review', 'published')
    and cat.name = p_category_name
  order by c.title, c.id
  offset p_offset
  limit p_limit;
end;
$$;

create or replace function public.internal_preview_search_contents(
  p_query text,
  p_limit integer default 30
)
returns table(
  id uuid,
  legacy_screen_id text,
  slug text,
  title text,
  summary text,
  content_kind text,
  premium boolean,
  medical_review_status text,
  source_last_reviewed_at timestamptz,
  published_at timestamptz,
  updated_at timestamptz,
  category_name text,
  category_slug text
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
  if nullif(btrim(coalesce(p_query, '')), '') is null then
    return;
  end if;
  if p_limit < 1 or p_limit > 100 then
    raise exception 'invalid_limit' using errcode = '22023';
  end if;

  return query
  select
    c.id, c.legacy_screen_id, c.slug, c.title, c.summary, c.content_kind,
    c.premium, c.medical_review_status, c.source_last_reviewed_at,
    c.published_at, c.updated_at, cat.name, cat.slug
  from public.contents c
  left join public.content_categories cc on cc.content_id = c.id and cc.is_primary
  left join public.categories cat on cat.id = cc.category_id
  where c.status in ('review', 'published')
    and (
      c.title ilike ('%' || btrim(p_query) || '%')
      or coalesce(c.summary, '') ilike ('%' || btrim(p_query) || '%')
    )
  order by case when lower(c.title) = lower(btrim(p_query)) then 0 else 1 end,
           c.title, c.id
  limit p_limit;
end;
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
      select jsonb_agg(jsonb_build_object(
        'id', a.id,
        'asset_type', a.asset_type,
        'access_scope', a.access_scope,
        'storage_path', a.storage_path,
        'caption', a.caption,
        'alt_text', a.alt_text,
        'sort_order', a.sort_order
      ) order by a.sort_order, a.id)
      from public.content_assets a
      where a.content_id = t.id
    ), '[]'::jsonb) as assets
  from target t;
end;
$$;

create or replace function public.internal_preview_curriculum_category_contents(
  p_program_code text,
  p_year_no integer,
  p_category_slug text,
  p_offset integer default 0,
  p_limit integer default 50
)
returns table(
  id uuid,
  legacy_screen_id text,
  slug text,
  title text,
  summary text,
  content_kind text,
  premium boolean,
  medical_review_status text,
  source_last_reviewed_at timestamptz,
  published_at timestamptz,
  updated_at timestamptz,
  category_name text,
  category_slug text
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
  if nullif(btrim(coalesce(p_program_code, '')), '') is null then
    raise exception 'program_code_required' using errcode = '22023';
  end if;
  if p_year_no not between 1 and 4 then
    raise exception 'invalid_year_no' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_category_slug, '')), '') is null then
    raise exception 'category_slug_required' using errcode = '22023';
  end if;
  if p_offset < 0 or p_limit < 1 or p_limit > 100 then
    raise exception 'invalid_pagination' using errcode = '22023';
  end if;

  return query
  select
    c.id, c.legacy_screen_id, c.slug, c.title, c.summary, c.content_kind,
    c.premium, c.medical_review_status, c.source_last_reviewed_at,
    c.published_at, c.updated_at, cat.name, cat.slug
  from public.contents c
  join public.content_categories cc on cc.content_id = c.id and cc.is_primary
  join public.categories cat on cat.id = cc.category_id and cat.is_active
  where c.status in ('review', 'published')
    and cat.slug = p_category_slug
    and (
      exists (
        select 1 from public.content_curriculum_overrides o
        where o.content_id = c.id
          and o.program_code = p_program_code
          and o.year_no = p_year_no
      )
      or (
        not exists (
          select 1 from public.content_curriculum_overrides ox
          where ox.content_id = c.id
            and ox.program_code = p_program_code
        )
        and exists (
          select 1 from public.category_curriculum_map m
          where m.program_code = p_program_code
            and m.year_no = p_year_no
            and m.category_id = cat.id
        )
      )
    )
  order by c.title, c.id
  offset p_offset
  limit p_limit;
end;
$$;

create or replace function public.internal_preview_get_quiz_questions(p_content_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  allowed boolean := false;
  result jsonb;
begin
  if not private.is_internal_preview_tester() then
    raise exception 'internal_preview_not_allowed' using errcode = '42501';
  end if;

  select exists (
    select 1
    from public.contents c
    where c.id = p_content_id
      and c.status in ('review', 'published')
      and c.content_kind = 'quiz'
  ) into allowed;

  if not allowed then
    return jsonb_build_object(
      'ok', false,
      'reason', 'not_found_or_no_access',
      'questions', '[]'::jsonb
    );
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', q.id,
        'key', q.question_key,
        'prompt', q.prompt,
        'ordinal', q.ordinal,
        'difficulty', q.difficulty,
        'lesson_content_id', q.lesson_content_id,
        'lesson_ordinal', q.lesson_ordinal,
        'lesson_title', lc.title,
        'lesson_slug', lc.slug,
        'choices', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'key', ch.choice_key,
                'text', ch.choice_text,
                'ordinal', ch.ordinal
              ) order by ch.ordinal
            ),
            '[]'::jsonb
          )
          from public.quiz_choices ch
          where ch.question_id = q.id
        )
      ) order by q.ordinal
    ),
    '[]'::jsonb
  )
  into result
  from public.quiz_questions q
  left join public.contents lc on lc.id = q.lesson_content_id
  where q.quiz_content_id = p_content_id;

  return jsonb_build_object('ok', true, 'questions', result);
end;
$$;

create or replace function private.submit_quiz_attempt_preview_impl(
  p_content_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  allowed boolean := false;
  total_count integer := 0;
  submitted_count integer := 0;
  distinct_question_count integer := 0;
  valid_answer_count integer := 0;
  correct_count integer := 0;
  attempt_uuid uuid;
  review_rows jsonb;
begin
  if uid is null or not private.is_internal_preview_tester() then
    raise exception 'internal_preview_not_allowed' using errcode = '42501';
  end if;

  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'answers_array_required' using errcode = '22023';
  end if;

  select exists (
    select 1
    from public.contents c
    where c.id = p_content_id
      and c.status in ('review', 'published')
      and c.content_kind = 'quiz'
  ) into allowed;

  if not allowed then
    raise exception 'quiz_not_found_or_no_access' using errcode = '42501';
  end if;

  select count(*)::integer into total_count
  from public.quiz_questions q
  where q.quiz_content_id = p_content_id;

  if total_count < 1 then
    raise exception 'quiz_has_no_questions' using errcode = '22000';
  end if;

  submitted_count := jsonb_array_length(p_answers);
  if submitted_count <> total_count then
    raise exception 'all_quiz_questions_must_be_answered' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_answers) x
    where jsonb_typeof(x) <> 'object'
       or coalesce(x->>'question_id', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
       or nullif(btrim(coalesce(x->>'choice_key', '')), '') is null
  ) then
    raise exception 'invalid_answer_payload' using errcode = '22023';
  end if;

  with submitted as (
    select (x->>'question_id')::uuid as question_id,
           upper(btrim(x->>'choice_key')) as choice_key
    from jsonb_array_elements(p_answers) x
  )
  select count(distinct question_id)::integer into distinct_question_count
  from submitted;

  if distinct_question_count <> total_count then
    raise exception 'duplicate_or_missing_quiz_question' using errcode = '22023';
  end if;

  with submitted as (
    select (x->>'question_id')::uuid as question_id,
           upper(btrim(x->>'choice_key')) as choice_key
    from jsonb_array_elements(p_answers) x
  )
  select count(*)::integer into valid_answer_count
  from submitted s
  join public.quiz_questions q
    on q.id = s.question_id
   and q.quiz_content_id = p_content_id
  join public.quiz_choices ch
    on ch.question_id = q.id
   and upper(ch.choice_key) = s.choice_key;

  if valid_answer_count <> total_count then
    raise exception 'invalid_quiz_question_or_choice' using errcode = '22023';
  end if;

  with submitted as (
    select (x->>'question_id')::uuid as question_id,
           upper(btrim(x->>'choice_key')) as choice_key
    from jsonb_array_elements(p_answers) x
  )
  select count(*)::integer into correct_count
  from submitted s
  join public.quiz_questions q
    on q.id = s.question_id
   and q.quiz_content_id = p_content_id
  join private.quiz_answer_keys k on k.question_id = q.id
  where s.choice_key = upper(k.correct_choice_key);

  insert into public.quiz_attempts(user_id, quiz_content_id, score, max_score)
  values (uid, p_content_id, correct_count, total_count)
  returning id into attempt_uuid;

  with submitted as (
    select (x->>'question_id')::uuid as question_id,
           upper(btrim(x->>'choice_key')) as choice_key
    from jsonb_array_elements(p_answers) x
  )
  insert into public.quiz_attempt_answers(attempt_id, question_id, selected_choice_key, is_correct)
  select attempt_uuid, q.id, s.choice_key, s.choice_key = upper(k.correct_choice_key)
  from submitted s
  join public.quiz_questions q
    on q.id = s.question_id
   and q.quiz_content_id = p_content_id
  join private.quiz_answer_keys k on k.question_id = q.id
  on conflict (attempt_id, question_id) do update
  set selected_choice_key = excluded.selected_choice_key,
      is_correct = excluded.is_correct;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'question_id', q.id,
        'question_key', q.question_key,
        'selected_choice_key', a.selected_choice_key,
        'correct_choice_key', k.correct_choice_key,
        'is_correct', coalesce(a.is_correct, false),
        'explanation', k.explanation
      ) order by q.ordinal
    ),
    '[]'::jsonb
  ) into review_rows
  from public.quiz_questions q
  join private.quiz_answer_keys k on k.question_id = q.id
  left join public.quiz_attempt_answers a
    on a.question_id = q.id
   and a.attempt_id = attempt_uuid
  where q.quiz_content_id = p_content_id;

  return jsonb_build_object(
    'ok', true,
    'attempt_id', attempt_uuid,
    'score', correct_count,
    'max_score', total_count,
    'percent', round((correct_count::numeric * 100.0) / total_count, 1),
    'review', review_rows
  );
end;
$$;

create or replace function public.internal_preview_submit_quiz_attempt(
  p_content_id uuid,
  p_answers jsonb
)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select private.submit_quiz_attempt_preview_impl(p_content_id, p_answers);
$$;

create or replace function public.service_internal_preview(
  p_user_id uuid,
  p_action text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_limit integer;
  v_offset integer;
  v_result jsonb;
begin
  perform private.set_internal_preview_claims(p_user_id);

  case v_action
    when 'categories' then
      select coalesce(jsonb_agg(to_jsonb(x) order by x.sort_order, x.name), '[]'::jsonb)
      into v_result
      from public.internal_preview_categories() x;
    when 'featured' then
      v_limit := least(greatest(coalesce(nullif(p_payload->>'limit','')::integer, 10), 1), 100);
      select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb)
      into v_result
      from public.internal_preview_featured_contents(v_limit) x;
    when 'category' then
      v_offset := greatest(coalesce(nullif(p_payload->>'offset','')::integer, 0), 0);
      v_limit := least(greatest(coalesce(nullif(p_payload->>'limit','')::integer, 50), 1), 100);
      select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb)
      into v_result
      from public.internal_preview_category_contents(
        coalesce(p_payload->>'category_name',''), v_offset, v_limit
      ) x;
    when 'search' then
      v_limit := least(greatest(coalesce(nullif(p_payload->>'limit','')::integer, 30), 1), 100);
      select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb)
      into v_result
      from public.internal_preview_search_contents(
        coalesce(p_payload->>'query',''), v_limit
      ) x;
    when 'detail' then
      select to_jsonb(x)
      into v_result
      from public.internal_preview_content_detail((p_payload->>'content_id')::uuid) x
      limit 1;
      v_result := coalesce(v_result, 'null'::jsonb);
    when 'curriculum' then
      v_offset := greatest(coalesce(nullif(p_payload->>'offset','')::integer, 0), 0);
      v_limit := least(greatest(coalesce(nullif(p_payload->>'limit','')::integer, 50), 1), 100);
      select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb)
      into v_result
      from public.internal_preview_curriculum_category_contents(
        coalesce(p_payload->>'program_code',''),
        (p_payload->>'year_no')::integer,
        coalesce(p_payload->>'category_slug',''),
        v_offset,
        v_limit
      ) x;
    when 'quiz_questions' then
      v_result := public.internal_preview_get_quiz_questions((p_payload->>'content_id')::uuid);
    when 'quiz_submit' then
      v_result := public.internal_preview_submit_quiz_attempt(
        (p_payload->>'content_id')::uuid,
        coalesce(p_payload->'answers', '[]'::jsonb)
      );
    else
      raise exception 'invalid_internal_preview_action' using errcode = '22023';
  end case;

  return v_result;
end;
$$;

-- Direct client execution is forbidden. Edge Function service access is explicit.
revoke execute on function private.is_internal_preview_tester() from public, anon, authenticated, service_role;
revoke execute on function private.set_internal_preview_claims(uuid) from public, anon, authenticated;
grant execute on function private.set_internal_preview_claims(uuid) to service_role;
revoke execute on function private.submit_quiz_attempt_preview_impl(uuid, jsonb) from public, anon, authenticated, service_role;

revoke execute on function public.internal_preview_categories() from public, anon, authenticated;
revoke execute on function public.internal_preview_featured_contents(integer) from public, anon, authenticated;
revoke execute on function public.internal_preview_category_contents(text, integer, integer) from public, anon, authenticated;
revoke execute on function public.internal_preview_search_contents(text, integer) from public, anon, authenticated;
revoke execute on function public.internal_preview_content_detail(uuid) from public, anon, authenticated;
revoke execute on function public.internal_preview_curriculum_category_contents(text, integer, text, integer, integer) from public, anon, authenticated;
revoke execute on function public.internal_preview_get_quiz_questions(uuid) from public, anon, authenticated;
revoke execute on function public.internal_preview_submit_quiz_attempt(uuid, jsonb) from public, anon, authenticated;
revoke execute on function public.service_internal_preview(uuid, text, jsonb) from public, anon, authenticated;

grant execute on function public.internal_preview_categories() to service_role;
grant execute on function public.internal_preview_featured_contents(integer) to service_role;
grant execute on function public.internal_preview_category_contents(text, integer, integer) to service_role;
grant execute on function public.internal_preview_search_contents(text, integer) to service_role;
grant execute on function public.internal_preview_content_detail(uuid) to service_role;
grant execute on function public.internal_preview_curriculum_category_contents(text, integer, text, integer, integer) to service_role;
grant execute on function public.internal_preview_get_quiz_questions(uuid) to service_role;
grant execute on function public.internal_preview_submit_quiz_attempt(uuid, jsonb) to service_role;
grant execute on function public.service_internal_preview(uuid, text, jsonb) to service_role;

-- Storage signing still runs under the signed-in user JWT, so this narrowly-scoped
-- helper is executable by authenticated solely for Storage RLS evaluation.
revoke execute on function private.can_access_internal_preview_media(text) from public, anon;
grant execute on function private.can_access_internal_preview_media(text) to authenticated, service_role;

drop policy if exists ftr_content_assets_read_entitled on storage.objects;
create policy ftr_content_assets_read_entitled
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'content-assets'
  and storage.allow_any_operation(array['object.get_authenticated_info','object.get_authenticated'])
  and (
    private.can_access_internal_preview_media(name)
    or exists (
      select 1
      from public.content_assets ca
      join public.contents c on c.id = ca.content_id
      where ca.storage_path = storage.objects.name
        and c.status = 'published'
        and (
          ca.access_scope = 'preview'
          or c.premium = false
          or private.has_active_entitlement()
        )
    )
  )
);
