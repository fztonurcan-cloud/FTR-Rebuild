import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sık Sorulan Sorular')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            const _FaqItem(
              question: 'FTR uygulaması kimler için?',
              answer:
                  'Fizyoterapi ve rehabilitasyon öğrencileri ile mesleki bilgisini tekrar etmek isteyen kullanıcılar için eğitim odaklı hazırlanmıştır.',
            ),
            const _FaqItem(
              question: 'İçerikler tıbbi tavsiye yerine geçer mi?',
              answer:
                  'Hayır. Uygulama eğitim ve sınava hazırlık içindir; tanı, kişiye özel tedavi, reçete veya acil sağlık hizmeti sunmaz.',
            ),
            const _FaqItem(
              question: 'Premium erişim nasıl açılır?',
              answer:
                  'Google Play satın alma işlemi tamamlandıktan sonra işlem sunucuda doğrulanır. Premium erişim yalnızca doğrulama başarılı olduğunda açılır.',
            ),
            const _FaqItem(
              question: 'Telefon değiştirirsem kayıtlarım kaybolur mu?',
              answer:
                  'Aynı FTR hesabıyla giriş yaptığınızda favoriler, notlar, ilerleme ve doğrulanmış Premium erişim hesabınızla senkronize edilir.',
            ),
            const _FaqItem(
              question: 'Satın almamı geri yükleyebilir miyim?',
              answer:
                  'Premium ekranındaki “Satın almayı geri yükle” seçeneği Google Play hesabındaki uygun satın almaları tekrar doğrulatır.',
            ),
            const _FaqItem(
              question: 'Hesabımı nasıl silebilirim?',
              answer:
                  'Profil → Gizlilik ve hesap → Hesabımı kalıcı olarak sil yolunu kullanabilirsiniz. Hesap silmek mağaza aboneliğini otomatik olarak iptal etmez.',
            ),
            const _FaqItem(
              question: 'Hasta bilgilerini notlara yazabilir miyim?',
              answer:
                  'Hayır. FTR bir hasta kayıt sistemi değildir. Hasta adı, kimlik bilgisi, tanı, dosya veya başka hassas sağlık verileri uygulamaya girilmemelidir.',
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Gizlilik Politikası'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: const Text('Kullanım Koşulları'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/legal/terms'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(answer)],
        ),
      );
}
