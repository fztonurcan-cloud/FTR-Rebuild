import '../../domain/models/ftr_content.dart';

String routeForContent(FtrContent content) {
  return content.isQuiz ? '/quiz/${content.id}' : '/content/${content.id}';
}
