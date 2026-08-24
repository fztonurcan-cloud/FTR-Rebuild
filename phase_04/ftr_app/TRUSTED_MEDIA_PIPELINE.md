# Trusted media pipeline (Phase 34)

The Flutter client has **read-only** access to entitled, published media and never receives a service-role key.

## Upload gate

`tools/trusted_media_upload.py` is dry-run by default. On a trusted maintainer/CI host, `--execute` performs all of the following before the database is updated:

1. Recompute the local file SHA-256 and size.
2. Upload to the private `content-assets` bucket at an immutable asset-bound path:
   `replacements/<content_uuid>/<replacement_asset_uuid>/<filename>`.
3. Download the stored object again and recompute SHA-256.
4. Call server-only `service_register_media_upload()`.
5. The RPC independently checks Storage existence, size, MIME type, expected database SHA, rights basis, and path binding.
6. A newly uploaded generated/design asset moves only to `review`, **not** to published content.

## Promotion gate

`service_promote_media_asset()` is server-only. It refuses promotion unless:

- `production_status = 'approved'`
- rights basis is not `pending`
- a Storage object exists
- `storage_path` and a 64-character SHA are present

Even after promotion, RLS serves the asset only when its content is `published`, and Premium protected media additionally requires an active entitlement.

## Secrets

Never place `SUPABASE_SERVICE_ROLE_KEY` or an `sb_secret_...` value in Flutter source, build args, downloadable checkpoints, screenshots, or committed `.env` files. The trusted uploader reads the key only from the process environment.
