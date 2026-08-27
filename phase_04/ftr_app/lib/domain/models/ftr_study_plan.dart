class FtrStudyPlanCategory {
  const FtrStudyPlanCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.priority,
    required this.publishedContentCount,
    required this.plannedContentCount,
    this.notes,
  });

  final String id;
  final String slug;
  final String name;
  final String priority;
  final int publishedContentCount;
  final int plannedContentCount;
  final String? notes;

  factory FtrStudyPlanCategory.fromMap(Map<String, dynamic> map) {
    return FtrStudyPlanCategory(
      id: map['id']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'support',
      publishedContentCount:
          (map['published_content_count'] as num?)?.toInt() ?? 0,
      plannedContentCount:
          (map['planned_content_count'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString(),
    );
  }
}

class FtrStudyPlan {
  const FtrStudyPlan({
    required this.programCode,
    required this.yearNo,
    required this.categories,
  });

  final String programCode;
  final int yearNo;
  final List<FtrStudyPlanCategory> categories;

  factory FtrStudyPlan.fromMap(Map<String, dynamic> map) {
    final rawCategories = map['categories'];
    final categories = rawCategories is List
        ? rawCategories
            .whereType<Map>()
            .map(
              (item) => FtrStudyPlanCategory.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <FtrStudyPlanCategory>[];

    return FtrStudyPlan(
      programCode: map['program_code']?.toString() ?? 'ftr_lisans_4y',
      yearNo: (map['year_no'] as num?)?.toInt() ?? 0,
      categories: categories,
    );
  }
}
