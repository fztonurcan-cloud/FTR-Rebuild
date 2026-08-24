# Legacy content seed

Hazırlanan eğitim kaydı: **321**
- APK içinden ham HTML kurtarılan: **78**
- Harici kaynak URL'si olan: **243**

## Güvenlik kararı
Tüm kayıtlar `status=review` ve `medical_review_status=needs_update` olarak hazırlanmıştır. Bu bilinçlidir: 2020 döneminden kalma sağlık içeriğini otomatik olarak yayınlamak güvenli değildir.

Ham APK HTML'i `legacy_body_html` alanına alınır; `body_html` alanına doğrudan yazılmaz. Böylece sanitize ve akademik/klinik gözden geçirme yapılmadan kullanıcıya sunulmaz.

## Sıra
1. `supabase_001_core_schema.sql`
2. `supabase_002_secure_content_access.sql`
3. `supabase_003_catalog_views.sql`
4. `supabase_004_migration_fields.sql`
5. `supabase_005_seed_categories.sql`
6. Supabase Table Editor ile `content_seed_review.csv` dosyasını `contents` tablosuna import et. `legacy_parent_sections` CSV'de okunabilir metindir; otomatik importtan sonra gerekirse array dönüşümü migration ile yapılır.
7. `supabase_006_assign_categories.sql`

Not: CSV importunda `legacy_parent_sections` text[] alanı doğrudan kabul etmezse bu alanı import dışında bırakacağız ve sonra JSON/SQL ile dolduracağız. Üretim için bu alan zorunlu değildir.
