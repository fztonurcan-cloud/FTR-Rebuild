import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('privileged QA preview routes through the internal Edge Function', () {
    final repository = File(
      'lib/data/repositories/supabase_ftr_repository.dart',
    ).readAsStringSync();
    final studyPlan = File(
      'lib/services/study_plan_service.dart',
    ).readAsStringSync();
    final previewService = File(
      'lib/services/internal_preview_service.dart',
    ).readAsStringSync();
    final quiz = File(
      'lib/services/quiz_service.dart',
    ).readAsStringSync();
    final edgeFunction = File(
      'supabase/functions/internal-preview/index.ts',
    ).readAsStringSync();

    expect(repository, contains("_preview.invoke('categories')"));
    expect(repository, isNot(contains('internal_preview_categories')));
    expect(repository, isNot(contains('internal_preview_content_detail')));

    expect(studyPlan, contains("'curriculum'"));
    expect(studyPlan, contains("category['planned_content_count']"));
    expect(studyPlan, isNot(contains('internal_preview_curriculum_category_contents')));

    expect(previewService, contains('_client.auth.currentSession'));
    expect(previewService, contains("'Authorization': 'Bearer \$accessToken'"));
    expect(previewService, contains('internal_preview_auth_required'));

    expect(quiz, contains("'quiz_questions'"));
    expect(quiz, contains("'quiz_submit'"));
    expect(quiz, isNot(contains('internal_preview_get_quiz_questions')));
    expect(quiz, isNot(contains('internal_preview_submit_quiz_attempt')));

    expect(edgeFunction, contains("@supabase/server@1.4.1"));
    expect(edgeFunction, contains("withSupabase({ auth: 'none' }"));
    expect(edgeFunction, contains('ctx.supabaseAdmin.auth.getUser(accessToken)'));
    expect(edgeFunction, contains("req.headers.get('Authorization')"));
    expect(edgeFunction, contains("service_internal_preview"));
  });
}
