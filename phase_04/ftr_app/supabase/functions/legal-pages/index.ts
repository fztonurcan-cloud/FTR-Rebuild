import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const UPDATED = "28 Ağustos 2026";

function page(title: string, body: string) {
  return `<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="index,follow"><title>${title} • FTR</title><style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;max-width:780px;margin:0 auto;padding:32px 20px;line-height:1.65;color:#18323a}h1,h2{line-height:1.25}h1{font-size:2rem}h2{margin-top:2rem;font-size:1.25rem}a{color:#176a78;font-weight:650}.card{background:#f4f8f9;border:1px solid #d9e4e7;border-radius:14px;padding:16px;margin:18px 0}small{color:#61777d}</style></head><body><h1>${title}</h1><small>Son güncelleme: ${UPDATED}</small>${body}<hr><small>FTR – Fizik Tedavi ve Rehabilitasyon eğitim uygulaması</small></body></html>`;
}

const privacy = page("Gizlilik Politikası", `
<div class="card"><strong>Özet:</strong> FTR, eğitim amaçlı bir fizyoterapi uygulamasıdır. Hesap verileri, öğrenme kayıtları ve doğrulanmış abonelik bilgileri yalnızca uygulama hizmetlerini sunmak, hesabı korumak ve Premium erişimi doğrulamak için işlenir. Kullanıcı verileri reklamverenlere satılmaz.</div>
<h2>1. Uygulama ve geliştirici iletişimi</h2><p>Bu politika <strong>FTR – Fizik Tedavi ve Rehabilitasyon</strong> uygulaması için geçerlidir. Gizlilik veya kişisel veri talepleri için Google Play mağaza sayfasında yer alan doğrulanmış geliştirici iletişim kanalını kullanabilirsiniz. Hesap silme talebi için ayrıca aşağıdaki harici hesap silme sayfası kullanılabilir.</p><p><a href="/functions/v1/account-deletion">FTR harici hesap silme sayfasını aç</a></p>
<h2>2. İşlenen veriler</h2><p>Hesap oluşturduğunuzda e-posta adresiniz ve kimlik doğrulama kayıtları; uygulamayı kullandığınızda favoriler, kişisel notlar, öğrenme ilerlemesi, quiz denemeleri ve çalışma tercihleri işlenebilir. Google Play üzerinden abonelik kullanıldığında ürün kimliği, abonelik durumu, satın alma doğrulama bilgileri, satın alma belirteci ve hesap eşleştirmesi için tek yönlü türetilmiş bir tanımlayıcı işlenebilir. Tam ödeme kartı bilgileri FTR tarafından alınmaz veya saklanmaz.</p>
<h2>3. Kullanım amaçları</h2><p>Veriler; oturum açma, cihazlar arası senkronizasyon, içerik erişimi, Premium yetkilendirme, satın alma doğrulama, dolandırıcılığı önleme, abonelik yaşam döngüsü, hesap silme ve hizmet güvenliğini sağlama amaçlarıyla kullanılır.</p>
<h2>4. Hizmet sağlayıcılar ve paylaşım</h2><p>Kimlik doğrulama, veritabanı, depolama ve sunucu işlevleri için Supabase altyapısı; Android uygulama dağıtımı, abonelik ve satın alma doğrulaması için Google Play/Google API hizmetleri kullanılabilir. Veriler yalnızca bu hizmetlerin çalışması için gerekli ölçüde ilgili sağlayıcılarla işlenir. FTR kullanıcı verilerini reklam amaçlı veri brokerlarına satmaz.</p>
<h2>5. Sağlık verileri</h2><p>FTR bir hasta kayıt sistemi değildir ve cihaz sağlık sensörü/Health Connect verisi istemek üzere tasarlanmamıştır. Kişisel not alanlarına hasta adı, kimlik numarası, tıbbi dosya, tanı veya başka hassas hasta verileri girilmemelidir.</p>
<h2>6. Güvenlik</h2><p>Kişisel veriler aktarım sırasında HTTPS ile korunur. Sunucu tarafında yetkilendirme, satır düzeyi güvenlik (RLS), kullanıcıya bağlı erişim kontrolleri ve abonelik için mağaza doğrulaması uygulanır. Supabase service-role/secret anahtarları mobil uygulamaya gömülmez.</p>
<h2>7. Saklama ve silme</h2><p>Kullanıcıya bağlı uygulama verileri hesap var olduğu sürece saklanabilir. Hesap kalıcı olarak silindiğinde uygulama veritabanındaki kullanıcı profili, favoriler, notlar, öğrenme ilerlemesi, quiz denemeleri, abonelik kaydı, satın alma olayları ve kullanıcıya bağlı Google Play doğrulama/eşleştirme kayıtları hesapla birlikte silinir. Güvenlik ve altyapı günlükleri, hizmet sağlayıcıların teknik saklama sürelerine veya zorunlu hukuki yükümlülüklere tabi olabilir; bu tür kayıtlar yeni bir kullanıcı hesabı oluşturmak veya reklam profili çıkarmak için kullanılmaz.</p>
<h2>8. Hesabı silme</h2><p>Uygulama içindeki <strong>Profil → Gizlilik ve hesap → Hesabımı kalıcı olarak sil</strong> yoluyla veya <a href="/functions/v1/account-deletion">harici hesap silme sayfasından</a> silme işlemi başlatılabilir. Google Play aboneliğinin otomatik yenilenmesi açıksa kullanıcıyı silmeden önce yenilemenin Play Store üzerinden durdurulması istenir. Hesap silme, mağaza aboneliğini kendi başına iptal etmez.</p>
<h2>9. Çocuklar</h2><p>Uygulama genel tüketici çocuk uygulaması olarak tasarlanmamıştır; fizyoterapi ve sağlık eğitimi alan kullanıcılar için hazırlanmıştır.</p>
<h2>10. Değişiklikler</h2><p>Bu politika hizmet, altyapı veya mevzuat değişiklikleri doğrultusunda güncellenebilir. Güncel ve geçerli sürüm her zaman bu sayfada yayımlanır.</p>
`);

const terms = page("Kullanım Koşulları ve Tıbbi Bilgilendirme", `
<div class="card"><strong>Önemli:</strong> FTR eğitim amaçlıdır ve tıbbi cihaz değildir; herhangi bir tıbbi durumu teşhis, tedavi, iyileştirme veya önleme amacı taşımaz. Tıbbi öneri, tanı veya tedavi için yetkin bir sağlık profesyoneline danışılmalıdır.</div>
<h2>1. Eğitim amacı</h2><p>Uygulamadaki dersler, quizler, görseller ve egzersiz açıklamaları fizyoterapi eğitimini desteklemek içindir. Klinik karar verirken yalnızca uygulamaya dayanılmamalı; güncel kılavuzlar, kurum protokolleri, cihaz üretici talimatları ve yetkin sağlık profesyoneli değerlendirmesi esas alınmalıdır.</p>
<h2>2. Acil durumlar</h2><p>Acil veya hızla kötüleşen bir sağlık durumunda uygulama kullanılmamalı; bulunduğunuz yerdeki acil sağlık hizmetlerine başvurulmalıdır.</p>
<h2>3. İçerik güvenliği</h2><p>Tıbbi, elektroterapi, egzersiz ve medya içerikleri yayın öncesi belirlenmiş inceleme kapılarından geçer. İnceleme tamamlanmamış içerikler yayınlanmaz. Buna rağmen bilimsel bilgi zamanla değişebilir.</p>
<h2>4. Hesap ve güvenlik</h2><p>Kullanıcı hesabının ve giriş bilgilerinin güvenliği kullanıcı sorumluluğundadır. Hizmetin kötüye kullanılması, yetkisiz erişim denemeleri veya teknik güvenlik mekanizmalarının aşılması yasaktır.</p>
<h2>5. Premium ve mağaza işlemleri</h2><p>Premium erişim yalnızca desteklenen Google Play işlemi sunucu tarafında doğrulandıktan sonra etkinleştirilir. Fiyat, yenileme dönemi, vergi ve iptal koşulları satın alma ekranında Google Play tarafından gösterilir. Aboneliğin iptali mağaza hesabından yönetilir.</p>
<h2>6. Fikri haklar</h2><p>Uygulamanın özgün yazılımı, düzeni ve özgün içerikleri ilgili hak sahiplerine aittir. Üçüncü taraf kaynaklar ve lisanslı materyaller kendi kullanım koşullarına tabidir.</p>
<h2>7. Değişiklikler</h2><p>Koşullar hizmetin gelişimine göre güncellenebilir. Güncel metin bu sayfada yayımlanır.</p>
`);

Deno.serve((req: Request) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return new Response("Method not allowed", { status: 405, headers: { allow: "GET, HEAD" } });
  }
  const url = new URL(req.url);
  const doc = url.searchParams.get("doc") ?? "privacy";
  const html = doc === "terms" ? terms : privacy;
  return new Response(req.method === "HEAD" ? null : html, {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "public, max-age=3600",
      "x-content-type-options": "nosniff",
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'",
      "referrer-policy": "no-referrer",
      "x-frame-options": "DENY",
    },
  });
});
