import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../features/content/presentation/content_detail_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';

class ContentRouteResolver extends ConsumerWidget {
  const ContentRouteResolver({required this.contentId, super.key});

  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentDetailProvider(contentId));
    return content.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('İçerik yüklenemedi: $error', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (item) {
        if (item == null) {
          return const Scaffold(body: Center(child: Text('İçerik bulunamadı.')));
        }
        if (item.isQuiz) return QuizScreen(contentId: contentId);
        return ContentDetailScreen(contentId: contentId);
      },
    );
  }
}
