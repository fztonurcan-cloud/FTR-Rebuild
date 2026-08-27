import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == LegalDocument.privacy;
    final title = isPrivacy
        ? 'Gizlilik Politikası'
        : 'Kullanım Koşulları ve Tıbbi Bilgilendirme';
    final sections = isPrivacy ? _privacySections : _termsSections;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Text(
            'Son güncelleme: 27 Ağustos 2026',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          _Notice(
            icon: isPrivacy ? Icons.privacy_tip_outlined : Icons.health_and_safety_outlined,
            text: isPrivacy
                ? 'FTR eğitim amaçlı bir fizyoterapi uygulamasıdır. Kullanıcı verileri hizmeti sunmak ve hesabı güvenli tutmak için işlenir; reklamverenlere satılmaz.'
                : 'FTR içeriği eğitim ve sınava hazırlık amacı taşır; tanı, kişiye özel tedavi, reçete veya acil sağlık hizmeti değildir.',
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(section.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

enum LegalDocument { privacy, terms }

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 11),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _LegalSection {
  const _LegalSection(this.title, this.body);
  final String title;
  final String body;
}

const _privacySections = <_LegalSection>[
  _LegalSection(
    '1. İşlenen veriler',
    'Hesap oluşturduğunuzda e-posta adresiniz ve kimlik doğrulama kayıtları; uygulamayı kullandığınızda favoriler, kişisel notlar, öğrenme ilerlemesi ve çalışma tercihleri işlenebilir. Google Play üzerinden abonelik kullanıldığında ürün kimliği, abonelik durumu ve satın alma doğrulama bilgileri işlenebilir. Tam ödeme kartı bilgileri FTR tarafından alınmaz veya saklanmaz.',
  ),
  _LegalSection(
    '2. Kullanım amaçları',
    'Veriler; oturum açma, cihazlar arası senkronizasyon, içerik erişimi, Premium yetkilendirme, satın alma doğrulama, dolandırıcılığı önleme, hesap silme ve hizmet güvenliğini sağlama amaçlarıyla kullanılır.',
  ),
  _LegalSection(
    '3. Hizmet sağlayıcılar',
    'Kimlik doğrulama, veritabanı ve sunucu işlevleri için Supabase altyapısı; Android uygulama dağıtımı ve abonelik işlemleri için Google Play hizmetleri kullanılabilir. Bu sağlayıcılar kendi sözleşme ve gizlilik kurallarına göre veri işleyebilir.',
  ),
  _LegalSection(
    '4. Sağlık verileri',
    'FTR bir hasta kayıt sistemi değildir. Uygulamanın not alanlarına hasta adı, kimlik numarası, tıbbi dosya, tanı veya başka hassas hasta verileri girilmemelidir. FTR kullanıcıdan klinik hasta verisi toplamak üzere tasarlanmamıştır.',
  ),
  _LegalSection(
    '5. Saklama ve güvenlik',
    'Kullanıcıya bağlı veriler hesap var olduğu sürece veya hizmetin ve hukuki yükümlülüklerin gerektirdiği süre boyunca saklanabilir. Yetkisiz erişimi azaltmak için sunucu tarafı yetkilendirme, satır düzeyi güvenlik ve abonelik doğrulaması uygulanır.',
  ),
  _LegalSection(
    '6. Hesabı silme',
    'Profil → Gizlilik ve hesap → Hesabımı kalıcı olarak sil yoluyla hesap silme başlatılabilir. Aktif mağaza aboneliğinin otomatik yenilenmesi varsa önce Google Play üzerinden iptal edilmesi gerekebilir. Hesap silme, Google Play aboneliğini tek başına iptal etmez.',
  ),
  _LegalSection(
    '7. Çocuklar',
    'Uygulama genel tüketici çocuk uygulaması olarak tasarlanmamıştır; fizyoterapi ve sağlık eğitimi alan kullanıcılar için hazırlanmıştır.',
  ),
  _LegalSection(
    '8. Değişiklikler',
    'Bu politika hizmet veya mevzuat değişiklikleri doğrultusunda güncellenebilir. Güncel sürüm uygulama içinde ve yayınlanan resmi politika sayfasında sunulur.',
  ),
];

const _termsSections = <_LegalSection>[
  _LegalSection(
    '1. Eğitim amacı',
    'Uygulamadaki dersler, quizler, görseller ve egzersiz açıklamaları fizyoterapi eğitimini desteklemek içindir. Klinik karar verirken yalnızca uygulamaya dayanılmamalı; güncel kılavuzlar, kurum protokolleri, cihaz üretici talimatları ve yetkin sağlık profesyoneli değerlendirmesi esas alınmalıdır.',
  ),
  _LegalSection(
    '2. Acil durumlar',
    'Acil veya hızla kötüleşen bir sağlık durumunda uygulama kullanılmamalı; bulunduğunuz yerdeki acil sağlık hizmetlerine başvurulmalıdır.',
  ),
  _LegalSection(
    '3. İçerik güvenliği',
    'Tıbbi, elektroterapi, egzersiz ve medya içerikleri yayın öncesi belirlenmiş inceleme kapılarından geçer. İnceleme tamamlanmamış içerikler yayınlanmaz. Buna rağmen bilimsel bilgi zamanla değişebilir.',
  ),
  _LegalSection(
    '4. Hesap ve güvenlik',
    'Kullanıcı hesabının ve giriş bilgilerinin güvenliği kullanıcı sorumluluğundadır. Hizmetin kötüye kullanılması, yetkisiz erişim denemeleri veya teknik güvenlik mekanizmalarının aşılması yasaktır.',
  ),
  _LegalSection(
    '5. Premium ve mağaza işlemleri',
    'Premium erişim yalnızca desteklenen mağaza işlemi sunucu tarafında doğrulandıktan sonra etkinleştirilir. Fiyat, yenileme dönemi, vergi ve iptal koşulları satın alma ekranında Google Play tarafından gösterilir. Aboneliğin iptali mağaza hesabından yönetilir.',
  ),
  _LegalSection(
    '6. Fikri haklar',
    'Uygulamanın özgün yazılımı, düzeni ve özgün içerikleri ilgili hak sahiplerine aittir. Üçüncü taraf kaynaklar ve lisanslı materyaller kendi kullanım koşullarına tabidir.',
  ),
  _LegalSection(
    '7. Değişiklikler',
    'Koşullar hizmetin gelişimine göre güncellenebilir. Güncel metin uygulama içinde ve resmi yayın sayfasında sunulur.',
  ),
];
