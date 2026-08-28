import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/ftr_content.dart';
import '../domain/models/ftr_study_plan.dart';
import 'internal_preview_service.dart';

class StudyPlanService {
  const StudyPlanService(
    this._client, {
    this.internalReviewPreview = false,
  });

  final SupabaseClient _client;
  final bool internalReviewPreview;

  static const programCode = 'ftr_lisans_4y';

  Future<FtrStudyPlan> fetchYear(int yearNo) async {
    if (yearNo < 1 || yearNo > 4) {
      throw ArgumentError.value(yearNo, 'yearNo', '1 ile 4 arasında olmalı.');
    }

    final raw = await _client.rpc(
      'get_release_study_plan',
      params: {
        'p_program_code': programCode,
        'p_year_no': yearNo,
      },
    );
    if (raw is Map) {
      return FtrStudyPlan.fromMap(Map<String, dynamic>.from(raw));
    }
    throw const FormatException('Müfredat yanıtı beklenen biçimde değil.');
  }

  Future<List<FtrContent>> fetchCategoryContents({
    required int yearNo,
    required String categorySlug,
    int offset = 0,
    int limit = 50,
  }) async {
    if (yearNo < 1 || yearNo > 4) {
      throw ArgumentError.value(yearNo, 'yearNo', '1 ile 4 arasında olmalı.');
    }
    if (categorySlug.trim().isEmpty) return const [];
    if (offset < 0 || limit < 1 || limit > 100) {
      throw ArgumentError('Geçersiz sayfalama parametreleri.');
    }

    final dynamic raw;
    if (internalReviewPreview) {
      raw = await InternalPreviewService(_client).invoke(
        'curriculum',
        payload: {
          'program_code': programCode,
          'year_no': yearNo,
          'category_slug': categorySlug.trim(),
          'offset': offset,
          'limit': limit,
        },
      );
    } else {
      raw = await _client.rpc(
        'get_curriculum_category_contents',
        params: {
          'p_program_code': programCode,
          'p_year_no': yearNo,
          'p_category_slug': categorySlug.trim(),
          'p_offset': offset,
          'p_limit': limit,
        },
      );
    }

    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => FtrContent.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }
}
