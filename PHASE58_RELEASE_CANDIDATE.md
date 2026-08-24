# FTR Phase 58 — Release Candidate Build Handoff

Main technical readiness remains **99%** because no real APK/AAB has been emitted yet.

## Completed in Phase 58
- Added GitHub Actions signed release workflow for Flutter 3.47.0 / Java 17 / Android 36.
- Release workflow produces both AAB and APK plus SHA-256 files and upload certificate fingerprints.
- Signing material exists only during the CI job and is removed in an `always()` cleanup step.
- Fixed a release-only configuration bug: `build_android_release.sh` now forwards Supabase and Play product IDs with `--dart-define`, matching `String.fromEnvironment` usage in the Flutter app.
- Added `release_dart_define_gate.py` so this cannot silently regress.
- Android package/version regression gate remains PASS.

## Required GitHub Actions secrets
- `FTR_UPLOAD_KEYSTORE_B64`
- `FTR_UPLOAD_STORE_PASSWORD`
- `FTR_UPLOAD_KEY_ALIAS`
- `FTR_UPLOAD_KEY_PASSWORD`
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `PLAY_MONTHLY_PRODUCT_ID`
- `PLAY_YEARLY_PRODUCT_ID`

## What still prevents 100%
A real repository/runner must execute the workflow and emit actual artifacts. After that, a device smoke test and real Google Play purchase/restore verification are still required.
