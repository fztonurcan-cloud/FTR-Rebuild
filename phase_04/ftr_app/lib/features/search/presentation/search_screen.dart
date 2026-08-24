import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  List<FtrContent> results = const [];

  Future<void> runSearch(String value) async {
    setState(() => loading = true);
    final data = await ref.read(ftrRepositoryProvider).search(value);
    if (!mounted) return;
    setState(() { results = data; loading = false; });
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ara', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      TextField(controller: controller, autofocus: true, textInputAction: TextInputAction.search, onSubmitted: runSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Örn. skolyoz, TENS, ACL...')),
      if (loading) const LinearProgressIndicator(),
      const SizedBox(height: 16),
      Expanded(child: results.isEmpty
        ? const Center(child: Text('Bir konu aratarak başlayabilirsin.'))
        : ListView.builder(itemCount: results.length, itemBuilder: (_, i) => Card(child: ListTile(
            title: Text(results[i].title), subtitle: Text(results[i].summary), onTap: () => context.push('/content/${results[i].id}'),
          )))),
    ]),
  ));
}
