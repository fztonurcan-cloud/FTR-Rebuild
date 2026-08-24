# FTR Billing Architecture

## Source of truth
Premium entitlement is never granted from the local purchase callback alone.

Android flow:
1. Flutter checks `billing-readiness`; if backend verification is not configured, purchase/restore UI is disabled.
2. Flutter receives a Google Play purchase update from the global purchase stream.
3. `verificationData.serverVerificationData` is sent to `verify-google-subscription`.
4. Edge Function authenticates the FTR user.
5. Edge Function calls Google Play Developer API `purchases.subscriptionsv2.get`.
6. The returned `productId` must be in `GOOGLE_PLAY_ALLOWED_PRODUCT_IDS`.
7. If Google returns `externalAccountIdentifiers.obfuscatedExternalAccountId`, it must match the signed-in Supabase user UUID. New Android purchases send that UUID as `applicationUserName`.
8. If acknowledgement is pending, the backend acknowledges the subscription.
9. Backend-only RPC persists the Google state and the derived entitlement.
10. Flutter refreshes `get_my_entitlement()`.
11. Only after server verification succeeds does Flutter call `completePurchase`.

RTDN flow:
1. Google Play publishes an RTDN to Cloud Pub/Sub.
2. Authenticated Pub/Sub push calls `google-play-rtdn`.
3. Endpoint validates Google OIDC issuer, audience, expected service-account email, email verification, expiry, and an additional secret query token.
4. Message ID is claimed idempotently.
5. RTDN payload is treated only as a change signal; it never grants entitlement by itself.
6. Backend re-fetches `purchases.subscriptionsv2.get`, validates product allowlist/account binding, and updates the same entitlement record.
7. Processing success/error is recorded for diagnostics and Pub/Sub retry behavior.

## Required production secrets
Android verification:
- `GOOGLE_PLAY_PACKAGE_NAME`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- `GOOGLE_PLAY_ALLOWED_PRODUCT_IDS` (comma-separated)

RTDN additionally requires:
- `GOOGLE_PUBSUB_AUDIENCE`
- `GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_PUBSUB_VERIFICATION_TOKEN`

Until the Android verification secrets are configured, `billing-readiness` reports not ready and the Flutter purchase UI stays disabled. The verification endpoint also fails closed with `billing_not_configured`.

## Entitlement states
Access allowed while not expired:
- `active`
- `grace`
- `canceled` (canceled but paid period not yet expired)

No access:
- `pending`
- `paused`
- `on_hold`
- `expired`
- `revoked`

## Product IDs
Current Flutter placeholders:
- `ftr_premium_monthly`
- `ftr_premium_yearly`

These are not production facts until the Play Console package/signing decision and subscription products are finalized. The backend product allowlist remains unset until then.

## iOS
The current app fails closed on iOS purchase verification (`app_store_not_configured`). App Store Server API / StoreKit entitlement verification must be implemented before iOS purchases are enabled.
