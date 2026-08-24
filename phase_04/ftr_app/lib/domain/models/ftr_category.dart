class FtrCategory {
  const FtrCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.count,
    this.description,
  });

  final String id;
  final String slug;
  final String name;
  final int count;
  final String? description;

  factory FtrCategory.fromMap(Map<String, dynamic> map) => FtrCategory(
        id: map['id'].toString(),
        slug: map['slug'] as String,
        name: map['name'] as String,
        count: (map['content_count'] as num?)?.toInt() ?? 0,
        description: map['description'] as String?,
      );
}
