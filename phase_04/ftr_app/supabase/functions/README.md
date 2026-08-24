# Supabase Edge Functions

Live deployed functions for the FTR project:

- `delete-account` — authenticated account deletion.
- `verify-google-subscription` — authenticated Google Play server verification; fail-closed without billing secrets.
- `google-play-rtdn` — Google Pub/Sub RTDN receiver with custom OIDC + audience/email/query-token verification.
- `billing-readiness` — public, non-sensitive readiness booleans used to disable purchase UI until verification is configured.
- `legacy-content-import` — legacy migration endpoint retained remotely in a disabled/410-era state; not part of the runtime business flow.

Never commit Google service-account JSON, Supabase secret/service-role keys, Pub/Sub verification tokens, or other production secrets to this repository.
