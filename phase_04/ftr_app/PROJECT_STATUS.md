# FTR Rebuild — Project Status

Checkpoint: 2026-08-28

## Current state

The project is no longer source-only. Android debug APK and release-mode AAB compilation have both been executed successfully in GitHub Actions with Flutter 3.47.0 / Dart 3.13.0 / Java 17.

### Android identity and release baseline

- Package/application ID: `com.mobiroller.mobi743032079412`
- Version: `4.0.0`
- Version code: `25`
- Confirmed previous Play highest version code: `24`
- compileSdk/targetSdk: 36
- minSdk: 24
- `pubspec.lock` is committed and strict preflight checks the locked dependency graph.
- Release signing is separated from debug signing and production CI fails closed without required signing material.

### Verified builds

- Live-Supabase debug APK CI: PASS (`33151808285`)
- Debug artifact SHA-256: `322c54a382ad2e32cf6d9cc363625323ec65605c56ff1749cfe39f5aa46c67b4`
- Release-mode AAB smoke CI with ephemeral non-Play signing key: PASS (`33151762191`)
- Smoke AAB was used only to prove the release pipeline and was never designated for Play upload.
- Temporary smoke workflow was deleted after successful validation.

### Live Supabase / security

- Production Supabase project is connected using public client configuration only.
- Supabase service-role/secret credentials are not shipped in Flutter.
- RLS and direct-role privilege review is complete for the reviewed private/editorial/billing tables.
- `anon`/`authenticated` direct DML remains denied on private service tables and `purchase_events`.
- Security advisor findings in this area are informational deny-by-default notices rather than unresolved exposure warnings.
- Historical import/media generator Edge Functions sampled in production are retired with HTTP 410 behavior.
- Google Play verification and RTDN functions contain server-side ownership, product allowlist and webhook identity checks.
- Account deletion requires authenticated/fresh-user confirmation and user-owned rows cascade from `auth.users`.

### Auth / billing / premium

- Email/password auth, recovery/deep-link flow, sign-out and auth-state tracking are implemented.
- Google Play purchase handling is designed to grant entitlement only after server verification.
- Purchase processing, restore behavior, entitlement refresh, account deletion, premium redaction and auth recovery have automated gates.
- Production release CI requires distinct monthly/yearly Play product IDs; blank IDs cannot produce a production release candidate.
- Real Play purchase/restore/cancel/expiry/RTDN validation remains pending until products and Play test track are configured.

### Play policy posture

- Main Android manifest currently requests only `android.permission.INTERNET`.
- Public privacy/terms Edge Function is deployed and source-controlled.
- Privacy text documents data categories, providers, security, retention/deletion and external account-deletion access.
- Terms state that FTR is educational, is not a medical device, and does not diagnose/treat/cure/prevent medical conditions.
- A Play policy regression gate blocks accidental introduction of sensitive Android permissions or removal of required privacy/deletion/medical-disclaimer text.

## Current device-test phase

The live-Supabase debug APK is under real-device validation. Device testing should cover:

- sign-up/sign-in/password recovery
- class/course/content navigation
- content detail/media rendering
- quiz behavior
- search
- favorites
- notes
- progress persistence
- premium locked/unlocked states
- offline/network-error states
- account deletion UX

## Remaining production blockers

1. Restore Google Play upload-key continuity or complete the upload-key reset using the prepared replacement certificate.
2. Confirm the accepted upload certificate fingerprint in Play Console.
3. Install the accepted upload keystore/password/alias values as GitHub Actions secrets.
4. Create/finalize monthly and yearly Google Play subscription products and configure their exact product IDs.
5. Complete Google Play Health Apps Declaration and store-listing medical disclaimer.
6. Confirm Play developer contact/privacy contact information and Data safety answers against the final app behavior.
7. Run the real signed release workflow and generate `FTR-release-4.0.0-25.aab`.
8. Upload the AAB to a Play test track and verify install/upgrade continuity from the existing listing.
9. Execute real Google Play purchase, restore, renewal, cancellation, expiry, RTDN and account-deletion interaction tests.
10. Promote only after device and Play-track validation are clean.

## Release rule

Do not upload an AAB to Google Play unless its signing certificate is the Play-accepted upload certificate and its package/version identity gates pass.
