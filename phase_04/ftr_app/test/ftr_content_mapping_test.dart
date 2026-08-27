import 'package:flutter_test/flutter_test.dart';
import 'package:ftr_app/domain/models/ftr_content.dart';

void main() {
  test('FtrContent parses verified sources, protected assets and content kind', () {
    final content = FtrContent.fromMap({
      'id': 'content-1',
      'slug': 'anatomiye-giris',
      'title': 'Anatomiye Giriş',
      'summary': 'Özet',
      'category_name': 'Temel Bilimler',
      'content_kind': 'quiz',
      'premium': true,
      'body_html': null,
      'medical_review_status': 'reviewed',
      'has_access': true,
      'sources': [
        {
          'title': 'Kaynak',
          'publisher': 'Yayıncı',
          'publication_year': 2026,
          'source_url': 'https://example.org/source',
          'verification_status': 'verified',
        }
      ],
      'assets': [
        {
          'id': 'asset-1',
          'asset_type': 'image',
          'access_scope': 'protected',
          'storage_path': 'content-1/figure.webp',
          'sort_order': 1,
          'caption': 'Şema',
          'alt_text': 'Anatomi şeması',
        }
      ],
    });

    expect(content.id, 'content-1');
    expect(content.premium, isTrue);
    expect(content.contentKind, 'quiz');
    expect(content.isQuiz, isTrue);
    expect(content.hasAccess, isTrue);
    expect(content.sources, hasLength(1));
    expect(content.assets, hasLength(1));
    expect(content.assets.single.isImage, isTrue);
    expect(content.assets.single.storagePath, 'content-1/figure.webp');
  });
}
