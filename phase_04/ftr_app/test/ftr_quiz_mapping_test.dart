import 'package:flutter_test/flutter_test.dart';
import 'package:ftr_app/domain/models/ftr_quiz.dart';

void main() {
  test('quiz question payload never requires an answer key', () {
    final question = FtrQuizQuestion.fromMap({
      'id': 'question-1',
      'key': 'Q1',
      'prompt': 'Soru?',
      'ordinal': 1,
      'difficulty': 'medium',
      'choices': [
        {'key': 'A', 'text': 'Bir', 'ordinal': 1},
        {'key': 'B', 'text': 'İki', 'ordinal': 2},
      ],
    });

    expect(question.id, 'question-1');
    expect(question.choices, hasLength(2));
    expect(question.choices.first.key, 'A');
  });

  test('graded result parses answer review only after submission', () {
    final result = FtrQuizResult.fromMap({
      'ok': true,
      'attempt_id': 'attempt-1',
      'score': 1,
      'max_score': 2,
      'percent': 50.0,
      'review': [
        {
          'question_id': 'question-1',
          'question_key': 'Q1',
          'selected_choice_key': 'A',
          'correct_choice_key': 'B',
          'is_correct': false,
          'explanation': 'Açıklama',
        }
      ],
    });

    expect(result.score, 1);
    expect(result.percent, 50.0);
    expect(result.review.single.correctChoiceKey, 'B');
  });
}
