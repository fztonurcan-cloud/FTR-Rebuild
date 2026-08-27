import 'ftr_asset.dart';
import 'ftr_source.dart';

class FtrContent {
  const FtrContent({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    required this.category,
    required this.premium,
    this.contentKind = 'article',
    this.bodyHtml,
    this.reviewStatus = 'pending',
    this.hasAccess = true,
    this.sources = const [],
    this.assets = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String summary;
  final String category;
  final bool premium;
  final String contentKind;
  final String? bodyHtml;
  final String reviewStatus;
  final bool hasAccess;
  final List<FtrSource> sources;
  final List<FtrAsset> assets;

  bool get isQuiz => contentKind == 'quiz';

  factory FtrContent.fromMap(Map<String, dynamic> map) {
    final rawSources = map['sources'];
    final sources = rawSources is List
        ? rawSources
            .whereType<Map>()
            .map((item) => FtrSource.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <FtrSource>[];

    final rawAssets = map['assets'];
    final assets = rawAssets is List
        ? rawAssets
            .whereType<Map>()
            .map((item) => FtrAsset.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <FtrAsset>[];

    return FtrContent(
      id: map['id'].toString(),
      slug: map['slug'] as String,
      title: map['title'] as String,
      summary: (map['summary'] as String?) ?? '',
      category: (map['category_name'] as String?) ?? '',
      premium: (map['premium'] as bool?) ?? false,
      contentKind: (map['content_kind'] as String?) ?? 'article',
      bodyHtml: map['body_html'] as String?,
      reviewStatus: (map['medical_review_status'] as String?) ?? 'pending',
      hasAccess: (map['has_access'] as bool?) ?? true,
      sources: sources,
      assets: assets,
    );
  }
}
