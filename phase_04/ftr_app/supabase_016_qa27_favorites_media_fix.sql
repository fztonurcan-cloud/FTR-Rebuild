-- QA27: favorites + signed media access hardening.
-- This migration does not publish review content or alter any human review state.

-- Favorites: Supabase upsert uses INSERT ... ON CONFLICT DO UPDATE, so the
-- authenticated role needs UPDATE privilege and an own-row UPDATE policy.
grant select, insert, update, delete on table public.favorites to authenticated;

drop policy if exists favorites_update_own on public.favorites;
create policy favorites_update_own
on public.favorites
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Production users still see only published favorites. Explicitly allowlisted
-- internal QA testers may also see their own favorites that are still in review.
create or replace function public.get_my_favorites()
returns table(
  id uuid,
  slug text,
  title text,
  summary text,
  content_kind text,
  premium boolean,
  medical_review_status text,
  category_name text,
  category_slug text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    c.id,
    c.slug,
    c.title,
    c.summary,
    c.content_kind,
    c.premium,
    c.medical_review_status,
    cat.name,
    cat.slug
  from public.favorites f
  join public.contents c on c.id = f.content_id
  left join public.content_categories cc
    on cc.content_id = c.id and cc.is_primary = true
  left join public.categories cat on cat.id = cc.category_id
  where f.user_id = (select auth.uid())
    and (
      c.status = 'published'
      or (
        c.status = 'review'
        and exists (
          select 1
          from private.preview_tester_registry r
          where r.user_id = (select auth.uid())
            and r.enabled
            and (r.expires_at is null or r.expires_at > now())
        )
      )
    )
  order by f.created_at desc;
$$;

revoke all on function public.get_my_favorites() from public, anon;
grant execute on function public.get_my_favorites() to authenticated, service_role;

-- createSignedUrl needs SELECT permission on storage.objects. The old QA policy
-- additionally constrained an internal storage operation name and rejected the
-- POST signing flow even though the same object was otherwise readable.
drop policy if exists ftr_content_assets_read_internal_preview on storage.objects;
drop policy if exists ftr_content_assets_read_entitled on storage.objects;

create policy ftr_content_assets_read_entitled
on storage.objects
for select
to anon, authenticated
using (
  bucket_id = 'content-assets'
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
