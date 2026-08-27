import 'package:flutter_test/flutter_test.dart';
import 'package:ftr_app/core/navigation/content_route.dart';
import 'package:ftr_app/domain/models/ftr_content.dart';

void main() {
  test('quiz content routes to dedicated quiz screen', () {
    const quiz = FtrContent(
      id: 'quiz-1',
      slug: 'quiz-1',
      title: 'Quiz',
      summary: '',
      category: 'Sınavlar',
      premium: true,
      contentKind: 'quiz',
    );
    expect(routeForContent(quiz), '/quiz/quiz-1');
  });

  test('article content routes to article detail screen', () {
    const article = FtrContent(
      id: 'article-1',
      slug: 'article-1',
      title: 'Article',
      summary: '',
      category: 'Temel Bilimler',
      premium: false,
    );
    expect(routeForContent(article), '/content/article-1');
  });
}
