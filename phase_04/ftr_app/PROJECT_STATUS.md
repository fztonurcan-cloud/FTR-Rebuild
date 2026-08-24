# FTR Rebuild — Project Status

Checkpoint: 2026-08-24

## Completed

### Legacy APK recovery
- Legacy package analyzed and content/navigation/premium mapping recovered.
- 321 education content records identified as legacy Premium content.
- 13-category replacement information architecture defined.
- 78 local legacy HTML bodies are preserved in the migration seed; 243 items depend on legacy external sources and require migration/review.

### Live Supabase
- Existing project `Fizik Tedavi Ve Rehabilitasyon` is used.
- Core tables, RLS policies, grants, views, indexes, auth profile trigger, and private staging schema are installed.
- 13 categories are live.
- 321/321 content metadata rows are live.
- 321/321 have a primary category.
- 0 legacy health contents are published automatically.
- All 321 are `review` + `needs_update` for clinical/content review safety.
- `get_content_detail`, `get_my_favorites`, and `get_my_notes` RPCs are live with security-invoker design.
- `delete-account` Edge Function is deployed with JWT verification.
- Temporary `legacy-content-import` Edge Function is disabled (JWT required + HTTP 410 behavior).

### Flutter source layer
- Material 3 design system and primary navigation.
- Home, Courses, Search, Content Detail, Premium, Favorites, Profile, Auth, Notes, and Account/Privacy screens.
- Supabase initialization with publishable key only.
- Email/password sign-up, sign-in, auth-state tracking, and sign-out.
- Favorites live service and UI.
- Notes CRUD live service and UI.
- Per-content user progress service and UI.
- Account deletion UI + trusted Edge Function.
- Premium screen intentionally does not grant or start paid entitlement until trusted store verification is implemented.

## Safety / security decisions
- No Supabase secret/service-role key is shipped in Flutter.
- Premium authorization is database-backed, not user-editable metadata.
- Old medical content is not auto-published.
- `purchase_events` has no client policy by design.
- Legacy body HTML is never copied into reviewed `body_html` without content review.

## Known environment limitation
This build container does not contain a Flutter SDK, so `flutter analyze`, native Android/iOS platform generation, and emulator/device compilation have not yet been executed here. Source code should be treated as implementation-ready but not yet compiler-verified.

## Next execution order
1. Finish the supported import path for the 78 legacy HTML bodies into `legacy_body_html` only.
2. Enrich all 321 metadata records with original source URL/type/date/clean slug.
3. Build clinical editorial/review workflow and start converting approved legacy content into new `body_html`.
4. Generate/compile Android + iOS Flutter platform projects with target Android API 36.
5. Configure production email delivery and password recovery/deep links.
6. Configure Google Play/App Store subscription products.
7. Implement trusted purchase verification Edge Functions and entitlement lifecycle.
8. Run device tests, security tests, Play/App Store compliance, and release build.
