import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/category_visuals.dart';
import '../../../data/providers.dart';
import '../../../domain/models/ftr_category.dart';
import '../../../domain/models/ftr_content.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final latest = ref.watch(featuredContentsProvider);

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 12, 6),
              child: Row(
                children: [
                  Expanded(child: Text('Dersler', style: Theme.of(context).textTheme.headlineMedium)),
                  IconButton(onPressed: () => context.go('/search'), icon: const Icon(Icons.search_rounded)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: TabBar(
                tabs: [Tab(text: 'Tüm Kategoriler'), Tab(text: 'Son Eklenenler')],
                indicatorColor: AppColors.primary600,
                labelColor: AppColors.primary700,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: AppColors.border,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  categories.when(
                    data: (items) => _CategoryList(items: items),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Kategoriler şu anda yüklenemedi.')),
                  ),
                  latest.when(
                    data: (items) => _LatestList(items: items),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Yeni içerikler şu anda yüklenemedi.')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.items});
  final List<FtrCategory> items;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          final item = items[index];
          final visual = categoryVisualFor(item.name);
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/courses/${item.slug}?name=${Uri.encodeQueryComponent(item.name)}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: visual.tint.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(visual.icon, color: visual.tint, size: 23),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            item.description?.trim().isNotEmpty == true ? item.description! : _fallbackDescription(item.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text('${item.count}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right_rounded, size: 19, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      );

  String _fallbackDescription(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('temel')) return 'Anatomi, fizyoloji, patoloji ve daha fazlası';
    if (lower.contains('ortoped')) return 'Omurga, üst-alt ekstremite ve spor yaralanmaları';
    if (lower.contains('nöro')) return 'SVO, MS, Parkinson ve daha fazlası';
    if (lower.contains('kardiyo')) return 'Kardiyak ve pulmoner rehabilitasyon';
    if (lower.contains('egzersiz')) return 'Bölgelere göre egzersizler';
    if (lower.contains('değerlend')) return 'Testler, ölçekler ve değerlendirmeler';
    if (lower.contains('modalite')) return 'Elektroterapi, termal ajanlar ve diğer modaliteler';
    if (lower.contains('manuel')) return 'Mobilizasyon ve manuel yaklaşımlar';
    if (lower.contains('ortez')) return 'Üst-alt ekstremite ve spinal ortezler';
    return 'FTR kütüphanesi';
  }
}

class _LatestList extends StatelessWidget {
  const _LatestList({required this.items});
  final List<FtrContent> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Henüz yayınlanmış yeni içerik yok.'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(12)),
              child: Icon(
                item.premium ? Icons.workspace_premium_outlined : Icons.menu_book_outlined,
                color: item.premium ? AppColors.premium : AppColors.primary600,
              ),
            ),
            title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/content/${item.id}'),
          ),
        );
      },
    );
  }
}
