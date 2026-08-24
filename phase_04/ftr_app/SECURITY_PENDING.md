# Pending Security Hardening

## Supabase RLS advisory on three legacy private tables

Supabase's table advisory flags Row Level Security as disabled on:

- `private.content_import_staging`
- `private.editorial_events`
- `private.legacy_import_archives`

Current explicit privilege checks show `anon` and `authenticated` have no SELECT/INSERT/UPDATE/DELETE privileges on these tables. The `private` schema is also not intended for mobile Data API access.

Supabase nevertheless recommends RLS as defense in depth. The suggested SQL is:

```sql
ALTER TABLE private.content_import_staging ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.editorial_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.legacy_import_archives ENABLE ROW LEVEL SECURITY;
```

This has intentionally NOT been applied automatically. Enabling RLS without defining the intended backend/service access path can block legitimate administrative/editorial operations. Before applying, define and test the service-only access model, then run the security advisor again.

## Billing secrets

No production Google service-account JSON, Supabase secret/service-role key, or Pub/Sub verification token is stored in the Flutter repository. The application must remain fail-closed until the Play package/signing decision and Play Console subscription products are finalized.
