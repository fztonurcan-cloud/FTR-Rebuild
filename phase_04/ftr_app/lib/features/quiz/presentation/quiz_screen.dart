import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers.dart';
import '../../../domain/models/ftr_quiz.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({required this.contentId, super.key});

  final String contentId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final Map<String, String> _answers = <String, String>{};
  bool _submitting = false;
  FtrQuizResult? _result;

  Future<void> _submit(List<FtrQuizQuestion> questions) async {
    if (_submitting || _result != null) return;
    if (_answers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sınavı göndermeden önce tüm soruları cevapla.')),
      );
      return;
    }

    final service = ref.read(quizServiceProvider);
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz servisi yapılandırılmamış.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await service.submitAttempt(widget.contentId, _answers);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sınav gönderilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    setState(() {
      _answers.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav'),
      ),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _LoginRequired(onTap: () => context.push('/auth')),
        data: (user) {
          if (user == null) {
            return _LoginRequired(onTap: () => context.push('/auth'));
          }

          final content = ref.watch(contentDetailProvider(widget.contentId));
          final questions = ref.watch(quizQuestionsProvider(widget.contentId));

          return questions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _QuizError(
              message: 'Sınav yüklenemedi: $error',
              onRetry: () => ref.invalidate(quizQuestionsProvider(widget.contentId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('Bu sınavda soru bulunmuyor.'));
              }

              final title = content.value?.title ?? 'FTR Sınavı';
              final reviewByQuestion = <String, FtrQuizReviewItem>{
                for (final item in _result?.review ?? const <FtrQuizReviewItem>[])
                  item.questionId: item,
              };

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    '${items.length} soru • Tüm sorular yanıtlanmadan gönderim yapılamaz.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _ResultCard(result: _result!),
                  ],
                  const SizedBox(height: 18),
                  for (final question in items) ...[
                    _QuestionCard(
                      question: question,
                      selected: _answers[question.id],
                      review: reviewByQuestion[question.id],
                      enabled: _result == null && !_submitting,
                      onSelected: (choiceKey) {
                        setState(() => _answers[question.id] = choiceKey);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_result == null)
                    FilledButton.icon(
                      onPressed: !_submitting && _answers.length == items.length
                          ? () => _submit(items)
                          : null,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_submitting ? 'Değerlendiriliyor…' : 'Sınavı bitir'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar çöz'),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selected,
    required this.review,
    required this.enabled,
    required this.onSelected,
  });

  final FtrQuizQuestion question;
  final String? selected;
  final FtrQuizReviewItem? review;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${question.ordinal}. ${question.prompt}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if ((question.lessonTitle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                question.lessonTitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            for (final choice in question.choices)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: choice.key,
                groupValue: selected,
                onChanged: enabled
                    ? (value) {
                        if (value != null) onSelected(value);
                      }
                    : null,
                title: Text('${choice.key}) ${choice.text}'),
              ),
            if (review != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    review!.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: review!.isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      review!.isCorrect
                          ? 'Doğru'
                          : 'Yanlış • Doğru cevap: ${review!.correctChoiceKey}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if ((review!.explanation ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review!.explanation!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final FtrQuizResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.fact_check_outlined, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '%${result.percent.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text('${result.score} / ${result.maxScore} doğru'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizError extends StatelessWidget {
  const _QuizError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 58),
              const SizedBox(height: 14),
              Text('Sınav için giriş yap', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Soru erişimi, premium yetkisi ve puanlama sunucu tarafında güvenli biçimde doğrulanır.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: const Text('Giriş yap / Hesap oluştur')),
            ],
          ),
        ),
      );
}
