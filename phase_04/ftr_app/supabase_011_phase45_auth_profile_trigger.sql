-- Mirrors the live auth profile creation trigger so source and production stay aligned.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.email));
  return new;
end;
$function$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

revoke all on function private.handle_new_user() from public, anon, authenticated;
grant execute on function private.handle_new_user() to postgres;
