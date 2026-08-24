# FTR Flutter iskeleti — Phase 04

Bu paket, yeni FTR uygulamasının ilk çalıştırılabilir kaynak iskeletidir. Ortamda Flutter SDK olmadığı için burada derleme yapılmamıştır; proje Flutter 3.47.x / Dart 3.12 çizgisi için hazırlanmıştır.

## Kurulum
1. Flutter 3.47 stable kurun.
2. Bu klasörde `flutter create . --org com.ftr --platforms android,ios` çalıştırın. Mevcut `lib/` ve `pubspec.yaml` dosyalarını koruyun.
3. `flutter pub get` çalıştırın.
4. Android `targetSdk` değerini 36 olarak doğrulayın.
5. Supabase hazır olana kadar uygulama otomatik Mock repository ile açılır.

## Supabase ile çalıştırma
Gizli/service-role anahtar kullanmayın. Mobil istemciye yalnızca publishable key verilir:

`flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`

## Paket kimliği
`com.ftr` yalnızca geçici geliştirme organizasyon kimliğidir. Eski Google Play kaydının signing durumu incelenmeden nihai applicationId seçilmeyecek.

## Premium
Flutter tarafında resmi `in_app_purchase` 3.3.0 kullanılır. Native Google Billing 9.1 mevcut olsa da resmi Flutter Android implementasyonu henüz Billing 8.0 kullanıyor; 9.x için resmi yükseltme çıktığında geçilecek.

Ürün kimlikleri geçici olarak `ftr_premium_monthly` ve `ftr_premium_yearly`. Gerçek ürünler Play Console'da oluşturulduktan sonra kesinleştirilecek. Fiyatlar uygulamaya sabit yazılmayacak; mağazadan alınacak.

### Editorial HTML rendering
Sanitized lesson HTML is rendered with `flutter_html`. Legacy `<img>`, `<iframe>`, active `<a>` tags, scripts, styles, and third-party hotlinks are removed by the Phase 05 pipeline before content can reach the app.

### Phase 19 build workflow
Use `tools/source_ci.sh` / `tools/source_ci.ps1` to run pub-get, preflight, analyze and tests when Flutter 3.47+ is available. Platform generation is deliberately separate: `tools/bootstrap_platforms.*` requires an explicitly confirmed final Android applicationId and iOS bundle ID. See `../../phase_19/BUILD_READINESS.md` and `../../phase_19/PACKAGE_IDENTITY_GATE.md`.
