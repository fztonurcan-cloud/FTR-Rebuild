# FTR Phase 59 — Real Build Validation Checkpoint

Date: 2026-08-28

## Confirmed

- Android package identity remains `com.mobiroller.mobi743032079412`.
- Version remains `4.0.0` (`versionCode 25`).
- Flutter 3.47.0 / Dart 3.13.0 / Java 17 / Android compile+target SDK 36 baseline is preserved.
- `pubspec.lock` is committed and strict release preflight now validates against a locked dependency graph.
- Premium-access gate was corrected to recognize formatted multi-line Dart RPC calls without weakening the semantic check.
- Debug CI produced a real APK with live Supabase public client configuration injected.
- Debug workflow run `33151808285` completed successfully, including identity gate, analyze, tests, APK build, checksum generation, and artifact upload.
- Release smoke workflow run `33151762191` completed successfully with an ephemeral non-Play signing key, including identity/signing/auth/billing/premium/account-deletion gates, strict preflight, analyze, tests, AAB build, checksum generation, and artifact upload.
- The temporary release-smoke workflow was deleted after validation so a smoke-signed AAB cannot be mistaken for a Play upload artifact.
- Supabase security advisor has no unresolved high-severity finding in the reviewed area; private/service tables remain RLS-enabled and fail closed to mobile roles.
- Android signing files and `android_release.env` are ignored by Git.

## Device-test artifact

Artifact name: `FTR-debug-4.0.0-25`

APK SHA-256:

`322c54a382ad2e32cf6d9cc363625323ec65605c56ff1749cfe39f5aa46c67b4`

This APK is for device validation, not Google Play production upload.

## Remaining external production blockers

1. Complete Google Play upload-key continuity/reset and wait for Play to accept the replacement upload certificate if the historic upload key cannot be recovered.
2. Install the accepted upload-key material as the four GitHub Actions signing secrets.
3. Finalize Play monthly/yearly subscription product IDs and configure them for release.
4. Run the real signed release workflow to emit `FTR-release-4.0.0-25.aab` and release APK with the Play-accepted upload key.
5. Upload the AAB to a Play test track and verify install/upgrade continuity.
6. Validate real Google Play purchase, restore, server verification, entitlement refresh, RTDN, cancellation/expiry, and account-deletion interactions.
7. Complete real-device UX/content smoke testing across authentication, lessons, quizzes, search, favorites, notes, progress, media, and offline/error states.

No production AAB should be uploaded to Play until the upload certificate fingerprint is confirmed against Play Console.
