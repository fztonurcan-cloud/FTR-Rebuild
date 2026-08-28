# FTR Phase 59 — Runtime Security Audit

Date: 2026-08-28

## Supabase database

Live checks confirm:

- RLS is enabled on the reviewed `private` tables.
- `anon` and `authenticated` have no direct DML privileges on the private editorial/import/billing tables reviewed.
- `public.purchase_events` is RLS-enabled; direct `anon`/`authenticated` DML is denied and backend `service_role` access remains available.
- Supabase security advisor findings in this area are INFO-level `RLS Enabled No Policy` notices, consistent with intentional deny-by-default service/private tables.
- No public policy was added merely to silence an INFO advisory.

## Edge Functions

Live deployed-function review confirms:

- `legacy-content-import` returns HTTP 410 and is retired.
- Sampled historical internal tools (`phase39-trusted-media-ingest`, `phase60-ppt-media-ingest`, `phase61-media-render-probe`, `phase61-media-review-producer`, `anatomy-core-2026-runner`, `pharm-2026-upload-a`) return HTTP 410 retired/disabled responses.
- `review-actions` requires an authenticated user and delegates authorization to service RPCs that enforce reviewer allowlisting/permissions; a valid JWT alone is insufficient for review actions.
- `verify-google-subscription` requires authenticated user context, validates the Google Play product allowlist, binds purchase ownership using the expected obfuscated account ID, uses Google Android Publisher verification, and fails closed when billing configuration is missing.
- `google-play-rtdn` intentionally has JWT verification disabled because it is a Pub/Sub webhook; the function performs its own Pub/Sub OIDC validation, expected audience check, expected service-account email check, expiry/issuer checks, and an additional verification token check before processing.
- `billing-readiness` is public but returns only boolean readiness/count/fingerprint metadata; it does not return service-account or private-key material.
- `account-deletion` is a public static account-deletion page; destructive deletion is delegated to the authenticated `delete-account` function after fresh credential verification.

## Release posture

- Supabase service-role/secret credentials are not shipped in Flutter.
- Android private signing material is not stored in the repository.
- `android_release.env`, JKS/keystore files, and Android `key.properties` are ignored by Git.
- Production release CI requires upload signing material plus distinct monthly/yearly Google Play product IDs before it can proceed.

## Remaining runtime validation

The remaining billing risk is external integration rather than missing application authorization logic: Google Play product creation, service-account/API access, RTDN Pub/Sub configuration, real purchase/restore/cancel/expiry testing, and upload-key continuity must still be validated on a Play test track before production rollout.
