# Security Status — 2026-08-28

## Supabase RLS status

The previously pending legacy-table RLS hardening is now verified as complete in the live Supabase project.

Verified live state:

- `private.content_import_staging` — RLS enabled
- `private.editorial_events` — RLS enabled
- `private.legacy_import_archives` — RLS enabled
- `anon` has no direct DML privileges on these tables
- `authenticated` has no direct DML privileges on these tables

The broader `private` schema tables are likewise RLS-enabled and direct mobile-role DML access is denied.

The Supabase security advisor currently reports only `RLS Enabled No Policy` informational notices for service/private tables. No permissive policies are added intentionally: for these tables, the absence of a policy preserves deny-by-default behavior rather than exposing rows to mobile roles.

`public.purchase_events` is also RLS-enabled; `anon` and `authenticated` have no direct DML privileges, while `service_role` retains the required backend access.

Reference for the informational advisor rule:
https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

## Billing / production secrets still pending

No production Google service-account JSON, Supabase service-role/secret key, upload keystore, or private signing password is stored in the Flutter repository.

Production release remains fail-closed until these external Play steps are completed:

1. Google Play upload-key continuity is restored or the prepared replacement upload certificate is accepted by Play Console.
2. The accepted upload keystore values are installed as GitHub Actions repository secrets.
3. Play monthly/yearly subscription product IDs are finalized and configured.
4. Google Play purchase, restore, server verification, and RTDN behavior are validated on a real Play test track.

Do not add public/mobile RLS policies to private billing or editorial tables merely to remove INFO advisor notices; doing so would widen the attack surface without an application requirement.
