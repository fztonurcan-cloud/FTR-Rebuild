-- The shared Storage SELECT policy serves both anonymous published assets and
-- authenticated internal QA preview assets. The helper returns false when
-- auth.uid() is null, so anon needs EXECUTE only to let the policy evaluate
-- without a permission error; it does not grant preview access.
grant execute on function private.can_access_internal_preview_media(text) to anon;
