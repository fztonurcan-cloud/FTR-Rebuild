import '../../domain/models/ftr_category.dart';
import '../../domain/models/ftr_content.dart';
import 'ftr_repository.dart';

class MockFtrRepository implements FtrRepository {
  const MockFtrRepository();

  static const _categories = <FtrCategory>[
    FtrCategory(id: 'cat_1', slug: 'temel-bilimler', name: 'Temel Bilimler', count: 72),
    FtrCategory(id: 'cat_2', slug: 'kinezyoloji-biyomekanik', name: 'Kinezyoloji & Biyomekanik', count: 10),
    FtrCategory(id: 'cat_3', slug: 'degerlendirme-muayene', name: 'Değerlendirme & Muayene', count: 15),
    FtrCategory(id: 'cat_4', slug: 'ortopedi-spor', name: 'Ortopedik & Spor Rehabilitasyon', count: 46),
    FtrCategory(id: 'cat_5', slug: 'norolojik-rehabilitasyon', name: 'Nörolojik Rehabilitasyon', count: 14),
    FtrCategory(id: 'cat_6', slug: 'kardiyopulmoner', name: 'Kardiyopulmoner Rehabilitasyon', count: 28),
    FtrCategory(id: 'cat_7', slug: 'pediatrik', name: 'Pediatrik Rehabilitasyon', count: 9),
    FtrCategory(id: 'cat_8', slug: 'ortez-protez', name: 'Ortez & Protez', count: 19),
    FtrCategory(id: 'cat_9', slug: 'fizik-tedavi-modaliteleri', name: 'Fizik Tedavi Modaliteleri', count: 30),
    FtrCategory(id: 'cat_10', slug: 'manuel-terapi', name: 'Manuel Terapi', count: 7),
    FtrCategory(id: 'cat_11', slug: 'egzersiz-kutuphanesi', name: 'Egzersiz Kütüphanesi', count: 24),
    FtrCategory(id: 'cat_12', slug: 'klinik-acil', name: 'Klinik & Acil', count: 43),
    FtrCategory(id: 'cat_13', slug: 'sinav-kaynaklar', name: 'Sınav & Kaynaklar', count: 4),
  ];

  static const _contents = <FtrContent>[
    FtrContent(id: 'demo_skolyoz', slug: 'skolyoz-rehabilitasyonu', title: 'Skolyoz Rehabilitasyonu', summary: 'Değerlendirme, sınıflandırma ve rehabilitasyon yaklaşımına giriş.', category: 'Ortopedik & Spor Rehabilitasyon', premium: true, bodyHtml: '<h2>Demo içerik</h2><p>Eski kaynak yeni sisteme taşındığında burada görüntülenecek.</p>', reviewStatus: 'needs_update'),
    FtrContent(id: 'demo_acl', slug: 'on-capraz-bag-rehabilitasyonu', title: 'Ön Çapraz Bağ Rehabilitasyonu', summary: 'ACL sonrası rehabilitasyonun temel evreleri.', category: 'Ortopedik & Spor Rehabilitasyon', premium: true, bodyHtml: '<h2>Demo içerik</h2><p>İçerik klinik gözden geçirme sonrası yayınlanacak.</p>'),
    FtrContent(id: 'demo_bridge', slug: 'kopru-egzersizi', title: 'Köprü (Bridge) Egzersizi', summary: 'Kalça ekstansörleri ve lumbopelvik stabilite için temel egzersiz.', category: 'Egzersiz Kütüphanesi', premium: false, bodyHtml: '<h2>Uygulama</h2><p>Sırtüstü pozisyonda kontrollü kalça ekstansiyonu.</p>'),
  ];

  @override
  Future<List<FtrCategory>> fetchCategories() async => _categories;

  @override
  Future<List<FtrContent>> fetchFeaturedContents() async => _contents;

  @override
  Future<List<FtrContent>> fetchContentsByCategory(
    String categoryName, {
    int offset = 0,
    int limit = 50,
  }) async {
    if (limit <= 0) return const [];
    final safeOffset = offset < 0 ? 0 : offset;
    return _contents
        .where((item) => item.category == categoryName)
        .skip(safeOffset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<FtrContent>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _contents.where((item) =>
      item.title.toLowerCase().contains(q) || item.summary.toLowerCase().contains(q)).toList();
  }

  @override
  Future<FtrContent?> fetchContentDetail(String id) async {
    for (final item in _contents) {
      if (item.id == id) return item;
    }
    return null;
  }
}
