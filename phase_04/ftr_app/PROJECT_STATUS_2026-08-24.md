# FTR Rebuild Status — 2026-08-24

## Completed
- APK content/config inventory and clean information architecture.
- 321 legacy learning contents migrated to Supabase metadata and categorized.
- All 321 clinical legacy contents remain unpublished and queued for review.
- 78 APK-local HTML bodies archived losslessly in private gzip archive (251,202 bytes, SHA-256 `26544dfedffdf652bffe11ed5d53afdda1249adba548cce15e1129c0cdfdce37`).
- 78/78 local bodies indexed to live content IDs with per-body SHA-256.
- Editorial review queue: 70 archived HTML, 8 mixed, 243 external-document records.
- 243 DocumentCloud legacy references preserved as unverified sources.
- Flutter UI skeleton, auth, favorites, notes, progress, account deletion.
- Premium body/assets protected by server-derived entitlement/RLS.
- Google Play billing DB state model and private raw purchase storage.
- `verify-google-subscription` Edge Function v2 deployed.
- `google-play-rtdn` Edge Function v2 deployed.
- `billing-readiness` Edge Function deployed.
- Google product allowlist and account binding (`obfuscatedAccountId`) enforced.
- Global Flutter purchase stream coordinator: verify server-side before `completePurchase`.
- Flutter Premium UI now disables purchase/restore while backend readiness is false.
- Current Edge Function TypeScript sources parse with 0 syntax errors.

## Intentionally not active yet
- Production Google Play package name.
- Google Play service-account credentials.
- Final monthly/yearly Play product IDs/base plans/offers.
- Pub/Sub RTDN audience/service-account/token configuration.
- iOS StoreKit/App Store Server API verification.
- Publishing of the 321 legacy clinical contents.

## Verification limitations in this environment
- Flutter SDK and Dart SDK are not installed, so `flutter analyze`, Android build, iOS build, and emulator/device tests have not yet been run here.
- This container cannot resolve external DNS, so live HTTP invocation of the deployed `billing-readiness` endpoint could not be tested from this environment. Supabase reports the functions as ACTIVE.

## Next production dependency
Resolve the old Play Console app/package/signing state before setting `GOOGLE_PLAY_PACKAGE_NAME` or creating/finalizing subscription product IDs.

## Phase 05 — Editorial migration pipeline
- 78/78 APK-embedded premium HTML lessons transformed deterministically.
- Source hash chain verified 78/78 against `private.legacy_body_index`.
- 1,338 remote media references removed from production HTML and inventoried separately.
- 8 legacy external anchors made inert and inventoried.
- `private.content_editorial_drafts` stores transform hashes/quality metadata.
- `private.content_revision_drafts` separates editorial rewrite approval from technical transform state.
- Publication trigger now requires an `approved` revision whose SHA matches current body for every legacy content item.
- Pilot `1623316` is `ready_for_medical_review` with two verified sources and remains unpublished.
- Content detail now uses `flutter_html ^3.0.0` instead of displaying HTML tags as plain text.

## Phase 19 — Exercise batch + build readiness
- Live revision count: 33; verified source rows: 92.
- Exercise safety reviews: 6; electrotherapy safety reviews: 10.
- Legacy published content remains 0.
- Shoulder and general knee exercise lessons added as original rewrites with 3 verified sources + 3 original media briefs each.
- Direct dependencies are exact-pinned for beta reproducibility.
- Source static preflight passes; Flutter/Dart compilation cannot run in this environment because SDKs are absent.
- Android/iOS platform generation is intentionally blocked until package/signing identity is resolved.
- Planned Android baseline: minSdk 24, compileSdk/targetSdk 36.
