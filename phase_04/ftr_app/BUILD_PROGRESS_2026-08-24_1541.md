# FTR rebuild — current build progress

Date: 2026-08-24

## Preserved foundations

- Existing Google Play listing continuity: package `com.mobiroller.mobi743032079412`.
- Highest legacy Play versionCode observed: `24`; new project baseline remains `4.0.0+25`.
- Supabase auth, premium entitlement, account deletion and secure content architecture remain intact.
- Premium/medical publication gates remain fail-closed.
- Legacy app structure remains the content/navigation reference, not a pixel-for-pixel UI template.

## UI work completed in this batch

- Reworked the home screen into a modern FTR library storefront.
- Preserved the legacy app's broad course/category idea while moving it to a cleaner Material 3 hierarchy.
- Added real category navigation from Home and Courses.
- Added category content lists backed by `content_catalog`.
- Added a repository method/provider for category-scoped content retrieval.
- Improved customer-facing hierarchy: hero area, search launcher, library discovery, featured lessons, Premium card and safety/trust messaging.
- No premium media is bundled locally in the APK source; protected media remains server-controlled.

## Validation

- Static source preflight: PASS.
- No relative import errors found.
- No secret-like values found in client source.
- No legacy media host references found in client source.
- Flutter/Dart compile is still blocked in this execution environment because Flutter SDK/Android SDK are not installed.

## Next build-critical work

1. Continue screen polish for Search, Profile and content navigation.
2. Keep media production separate from APK build critical path.
3. Generate Android platform files with Flutter 3.47 on a build-capable host.
4. Run `flutter pub get`, `flutter analyze`, tests and debug APK build.
5. Only after debug APK validation, create local upload key/reset Play upload certificate and build release AAB.
