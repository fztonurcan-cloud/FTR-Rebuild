import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/content_route.dart';
import '../../../data/providers.dart';
import '../../../domain/models/ftr_content.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  bool loading = false;
  bool searched = false;
  String? errorMessage;
  List<FtrContent> results = const [];

  Future<void> runSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        results = const [];
        searched = false;
        loading = false;
        errorMessage = null;
      });
      return;
    }

    setState(() {
      loading = true;
      searched = true;
      errorMessage = null;
    });

    try {
      final data = await ref.read(ftrRepositoryProvider).search(query);
      if (!mounted) return;
      setState(() {
        results = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        results = const [];
        loading = false;
        errorMessage = 'Arama şu anda tamamlanamadı. Lütfen tekrar dene.';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Geri',
                      onPressed: () => context.canPop() ? context.pop() : context.go('/courses'),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text('Ara', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: runSearch,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Örn. skolyoz, TENS, ACL...',
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Temizle',
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                results = const [];
                                searched = false;
                                errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                if (loading) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Expanded(child: _buildResults(context)),
              ],
            ),
          ),
        ),
      );

  Widget _buildResults(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 10),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => runSearch(controller.text),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (!searched) {
      return const Center(child: Text('Bir konu aratarak başlayabilirsin.'));
    }

    if (!loading && results.isEmpty) {
      return const Center(child: Text('Aramana uygun yayınlanmış içerik bulunamadı.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Card(
          child: ListTile(
            leading: Icon(item.isQuiz ? Icons.quiz_outlined : Icons.menu_book_outlined),
            title: Text(item.title),
            subtitle: Text(
              item.summary.trim().isEmpty
                  ? (item.isQuiz ? 'Sınav' : item.category)
                  : item.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(routeForContent(item)),
          ),
        );
      },
    );
  }
}
