import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/ftr_quiz.dart';
import 'internal_preview_service.dart';

class QuizService {
  const QuizService(
    this._client, {
    this.internalReviewPreview = false,
  });

  final SupabaseClient _client;
  final bool internalReviewPreview;

  Future<List<FtrQuizQuestion>> fetchQuestions(String contentId) async {
    if (_client.auth.currentUser == null) {
      throw AuthException('Sınava erişmek için giriş yapmalısın.');
    }

    final dynamic raw;
    if (internalReviewPreview) {
      raw = await InternalPreviewService(_client).invoke(
        'quiz_questions',
        payload: {'content_id': contentId},
      );
    } else {
      raw = await _client.rpc(
        'get_quiz_questions',
        params: {'p_content_id': contentId},
      );
    }

    final payload = _asMap(raw);
    if (payload['ok'] != true) {
      throw StateError(payload['reason']?.toString() ?? 'Sınava erişilemiyor.');
    }

    final rawQuestions = payload['questions'];
    if (rawQuestions is! List) return const [];
    return rawQuestions
        .whereType<Map>()
        .map((item) => FtrQuizQuestion.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<FtrQuizResult> submitAttempt(
    String contentId,
    Map<String, String> answers,
  ) async {
    if (_client.auth.currentUser == null) {
      throw AuthException('Sınavı göndermek için giriş yapmalısın.');
    }

    final payload = answers.entries
        .map((entry) => {
              'question_id': entry.key,
              'choice_key': entry.value,
            })
        .toList(growable: false);

    final dynamic raw;
    if (internalReviewPreview) {
      raw = await InternalPreviewService(_client).invoke(
        'quiz_submit',
        payload: {
          'content_id': contentId,
          'answers': payload,
        },
      );
    } else {
      raw = await _client.rpc(
        'submit_quiz_attempt',
        params: {
          'p_content_id': contentId,
          'p_answers': payload,
        },
      );
    }

    final result = _asMap(raw);
    if (result['ok'] != true) {
      throw StateError('Sınav sonucu alınamadı.');
    }
    return FtrQuizResult.fromMap(result);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Beklenmeyen quiz yanıtı.');
  }
}
