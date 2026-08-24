# Supabase canlı backend durumu — 24 Ağustos 2026

Proje: **Fizik Tedavi Ve Rehabilitasyon**
Durum: **ACTIVE_HEALTHY**

## Canlıda kurulan çekirdek
- profiles
- categories
- contents
- content_bodies
- content_categories
- content_assets
- favorites
- notes
- user_progress
- subscriptions
- purchase_events
- private.content_import_staging

RLS tüm kullanıcıya/aboneliğe bağlı tablolarda etkin.
Premium ders gövdeleri `content_bodies` üzerinden entitlement kontrolüyle okunur.
Premium asset metadata erişimi de aynı abonelik kuralına tabidir.
`purchase_events` istemciden yazılamaz; trusted backend/Edge Function içindir.

## Seed
- 13 ana kategori canlı veritabanına yüklendi.
- 321 eski eğitim içeriğinin migration dosyası hazır; sağlık içeriği klinik/akademik gözden geçirme olmadan `published` yapılmayacak.
- APK'dan kurtarılan ham HTML doğrudan kullanıcıya render edilmeyecek; önce sanitize + review yapılacak.

## Advisors
Supabase security advisor'da kritik açık yok. `purchase_events` için RLS policy olmaması bilinçlidir: tablo client erişimine kapalıdır.
Performance advisor'ın önerdiği foreign-key indeksleri eklendi.

## 2026-08-24 — Live migration checkpoint

- 321/321 legacy education records are present in `public.contents`.
- All 321 are intentionally `status=review`, `premium=true`, `medical_review_status=needs_update`.
- Every content record has one primary relationship to the 13-category architecture.
- Live primary counts: 72 / 10 / 15 / 46 / 14 / 28 / 9 / 19 / 30 / 7 / 24 / 43 / 4.
- `get_content_detail(uuid)` RPC now exists and uses `security invoker`.
- Premium body content remains separated from public metadata by `content_bodies` RLS.
- Legacy HTML remains migration-only material and must not be copied into `body_html` until review.

## Auth implementation checkpoint

- Email/password sign-up and sign-in service added.
- Auth state is exposed through Riverpod.
- Profile and Favorites screens react to signed-in/signed-out state.
- Anonymous browsing remains allowed; account is required for personal state and Premium identity.
- Production SMTP, password recovery deep-linking, Google/Apple identity providers, account deletion, and store entitlement verification are intentionally later launch tasks.

- Legacy HTML batch files were prepared locally (78 records / 9 batches). Direct invocation from the build container was blocked by its network/DNS sandbox, so no legacy body row was written through that route. The temporary importer is disabled after the attempt; raw HTML remains safely local until a supported import path is used.

## Editorial live status — 2026-08-24
- `private.content_editorial_drafts`: 78 rows
- `private.content_revision_drafts`: 1 row
- `private.content_review_events`: 79 rows (78 technical transforms + 1 editorial revision ready)
- ready for medical review: 1
- published legacy content: 0
- pilot verified sources: 2
- legacy publication gate: requires body + matching approved revision + medical review + verified source

## Phase 19 live counters
- content_revision_drafts: 33 total / 33 ready_for_medical_review
- exercise_safety_reviews: 6 total / 6 ready_for_safety_review
- electrotherapy_safety_reviews: 10 total
- verified content_sources: 92
- published legacy contents: 0
