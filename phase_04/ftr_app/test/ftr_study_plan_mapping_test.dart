import 'package:flutter_test/flutter_test.dart';
import 'package:ftr_app/domain/models/ftr_study_plan.dart';

void main() {
  test('release study plan parses published and planned counts', () {
    final plan = FtrStudyPlan.fromMap({
      'program_code': 'ftr_lisans_4y',
      'year_no': 3,
      'categories': [
        {
          'id': 'cat-1',
          'slug': 'ortopedi-spor',
          'name': 'Ortopedik & Spor Rehabilitasyon',
          'priority': 'core',
          'published_content_count': 12,
          'planned_content_count': 87,
          'notes': 'Klinik çekirdek',
        },
      ],
    });

    expect(plan.programCode, 'ftr_lisans_4y');
    expect(plan.yearNo, 3);
    expect(plan.categories, hasLength(1));
    expect(plan.categories.single.publishedContentCount, 12);
    expect(plan.categories.single.plannedContentCount, 87);
    expect(plan.categories.single.priority, 'core');
  });
}
