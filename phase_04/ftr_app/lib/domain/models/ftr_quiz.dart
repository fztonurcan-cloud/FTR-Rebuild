class FtrQuizChoice {
  const FtrQuizChoice({
    required this.key,
    required this.text,
    required this.ordinal,
  });

  final String key;
  final String text;
  final int ordinal;

  factory FtrQuizChoice.fromMap(Map<String, dynamic> map) => FtrQuizChoice(
        key: map['key']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        ordinal: (map['ordinal'] as num?)?.toInt() ?? 0,
      );
}

class FtrQuizQuestion {
  const FtrQuizQuestion({
    required this.id,
    required this.key,
    required this.prompt,
    required this.ordinal,
    required this.difficulty,
    required this.choices,
    this.lessonContentId,
    this.lessonOrdinal,
    this.lessonTitle,
    this.lessonSlug,
  });

  final String id;
  final String key;
  final String prompt;
  final int ordinal;
  final String difficulty;
  final List<FtrQuizChoice> choices;
  final String? lessonContentId;
  final int? lessonOrdinal;
  final String? lessonTitle;
  final String? lessonSlug;

  factory FtrQuizQuestion.fromMap(Map<String, dynamic> map) {
    final rawChoices = map['choices'];
    final choices = rawChoices is List
        ? rawChoices
            .whereType<Map>()
            .map((item) => FtrQuizChoice.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <FtrQuizChoice>[];

    return FtrQuizQuestion(
      id: map['id']?.toString() ?? '',
      key: map['key']?.toString() ?? '',
      prompt: map['prompt']?.toString() ?? '',
      ordinal: (map['ordinal'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty']?.toString() ?? '',
      choices: choices,
      lessonContentId: map['lesson_content_id']?.toString(),
      lessonOrdinal: (map['lesson_ordinal'] as num?)?.toInt(),
      lessonTitle: map['lesson_title']?.toString(),
      lessonSlug: map['lesson_slug']?.toString(),
    );
  }
}

class FtrQuizReviewItem {
  const FtrQuizReviewItem({
    required this.questionId,
    required this.questionKey,
    required this.selectedChoiceKey,
    required this.correctChoiceKey,
    required this.isCorrect,
    this.explanation,
  });

  final String questionId;
  final String questionKey;
  final String? selectedChoiceKey;
  final String correctChoiceKey;
  final bool isCorrect;
  final String? explanation;

  factory FtrQuizReviewItem.fromMap(Map<String, dynamic> map) => FtrQuizReviewItem(
        questionId: map['question_id']?.toString() ?? '',
        questionKey: map['question_key']?.toString() ?? '',
        selectedChoiceKey: map['selected_choice_key']?.toString(),
        correctChoiceKey: map['correct_choice_key']?.toString() ?? '',
        isCorrect: (map['is_correct'] as bool?) ?? false,
        explanation: map['explanation']?.toString(),
      );
}

class FtrQuizResult {
  const FtrQuizResult({
    required this.attemptId,
    required this.score,
    required this.maxScore,
    required this.percent,
    required this.review,
  });

  final String attemptId;
  final int score;
  final int maxScore;
  final double percent;
  final List<FtrQuizReviewItem> review;

  factory FtrQuizResult.fromMap(Map<String, dynamic> map) {
    final rawReview = map['review'];
    final review = rawReview is List
        ? rawReview
            .whereType<Map>()
            .map((item) => FtrQuizReviewItem.fromMap(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <FtrQuizReviewItem>[];

    return FtrQuizResult(
      attemptId: map['attempt_id']?.toString() ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      maxScore: (map['max_score'] as num?)?.toInt() ?? 0,
      percent: (map['percent'] as num?)?.toDouble() ?? 0,
      review: review,
    );
  }
}
