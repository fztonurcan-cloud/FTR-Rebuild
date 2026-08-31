# FTR v56 AI — Google Play Billing Plan

Date: 2026-08-31

## Active checkpoint

This document applies to the current v56 AI / free-TTS APK line. Do not use it to revive the abandoned Flutter rebuild as the APK source of truth.

Current Android package in the v56 AI APK line: `com.ftrakademi.preview3`.

Important unresolved release fork: an older Play/rebuild checklist in this repository targets the historic package `com.mobiroller.mobi743032079412`. Before Play Console products or `GOOGLE_PLAY_PACKAGE_NAME` are finalized, confirm whether release strategy is:

1. update/republish the historic Play listing (historic package must be preserved), or
2. publish a new Play listing (current package may be used).

Do not mix package identities.

## Canonical subscription catalog prepared in Supabase

Use one subscription product per entitlement and two auto-renewing base plans per product.

| Entitlement | Product ID | Base plans | Reference TRY price |
| --- | --- | --- | --- |
| 1. Sınıf | `ftr_class_1` | `monthly` / `yearly` | ₺299 / ₺2499 |
| 2. Sınıf | `ftr_class_2` | `monthly` / `yearly` | ₺299 / ₺2499 |
| 3. Sınıf | `ftr_class_3` | `monthly` / `yearly` | ₺299 / ₺2499 |
| 4. Sınıf | `ftr_class_4` | `monthly` / `yearly` | ₺299 / ₺2499 |
| Tüm FTR | `ftr_all_classes` | `monthly` / `yearly` | ₺599 / ₺4999 |

Billing periods:
- `monthly` = `P1M`
- `yearly` = `P1Y`

The price values above are release-planning reference values only. The shipped purchase UI must display localized price data returned by Google Play `ProductDetails`; do not trust hardcoded client prices as the transaction source of truth.

## Supabase backend status

Prepared:
- private Google Play product catalog
- private base-plan catalog
- authenticated client catalog RPC
- deterministic obfuscated account identifier binding
- purchase-token ownership protection
- Google `subscriptionsv2.get` verification Edge Function
- server-side acknowledgement
- server-only entitlement persistence
- RTDN/Pub/Sub receiver with OIDC + audience + service-account-email + verification-token checks
- idempotent RTDN message claiming
- active/grace/canceled-paid-period entitlement mapping
- paused/on-hold/expired/pending deny mapping
- database-level product/base-plan allow check
- database-level account-identity check

Required external production configuration remains:
- `GOOGLE_PLAY_PACKAGE_NAME`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- `GOOGLE_PLAY_ALLOWED_PRODUCT_IDS=ftr_class_1,ftr_class_2,ftr_class_3,ftr_class_4,ftr_all_classes`
- `GOOGLE_PUBSUB_AUDIENCE`
- `GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_PUBSUB_VERIFICATION_TOKEN`

## Android client work still required

The current v56 AI APK does not yet contain a Google Play `BillingClient` integration. The purchase screen is informational and explicitly says purchase initiation is not connected.

Native client integration must:
1. use the current Google Play Billing Library supported for release,
2. query the 5 subscription product IDs with `ProductType.SUBS`,
3. display localized Play prices,
4. choose the requested `monthly` or `yearly` base-plan offer token,
5. obtain the FTR account's obfuscated Google Play account identifier from the authenticated backend,
6. pass that identifier to the Play billing flow,
7. on purchase update, send the purchase token to `verify-google-subscription`,
8. unlock Premium only after server verification succeeds,
9. query/restore existing purchases on startup/account screen,
10. refresh server entitlement after purchase/restore,
11. provide a Play subscription-management link,
12. test purchase, renewal, cancel-at-period-end, grace, on-hold, expiry, restore, account mismatch, and RTDN.

## Release rule

Do not create irreversible Play Console configuration under a package until package continuity is confirmed. Do not grant Premium from a local purchase callback alone. Google Play + backend verification remains the entitlement source of truth.
