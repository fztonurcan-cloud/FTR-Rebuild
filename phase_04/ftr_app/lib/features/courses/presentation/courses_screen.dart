import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/content_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/category_visuals.dart';
import '../../../data/providers.dart';
import '../../../domain/models/ftr_category.dart';
import '../../../domain/models/ftr_content.dart';
import '../../../domain/models/ftr_study_plan.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final latest = ref.watch(featuredContentsProvider);

    return SafeArea(
      child: DefaultTabController(
        length: 6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dersler', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Türkiye FTR lisans müfredatı • 4 yıllık öğrenme yolu',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ara',
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: '1. Sınıf'),
                  Tab(text: '2. Sınıf'),
                  Tab(text: '3. Sınıf'),
                  Tab(text: '4. Sınıf'),
                  Tab(text: 'Tüm Kategoriler'),
                  Tab(text: 'Son Eklenenler'),
                ],
                indicatorColor: AppColors.primary600,
                labelColor: AppColors.primary700,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: AppColors.border,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (var year = 1; year <= 4; year++) _YearPlan(yearNo: year),
                  categories.when(
                    data: (items) => _CategoryList(items: items),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const _RetryHint(text: 'Kategoriler şu anda yüklenemedi.'),
                  ),
                  latest.when(
                    data: (items) => _LatestList(items: items),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const _RetryHint(text: 'Yeni içerikler şu anda yüklenemedi.'),
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

class _YearPlan extends ConsumerWidget {
  const _YearPlan({required this.yearNo});

  final int yearNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(studyPlanProvider(yearNo));
    return plan.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _RetryState(
        text: '$yearNo. sınıf müfredatı yüklenemedi.',
        onRetry: () => ref.invalidate(studyPlanProvider(yearNo)),
      ),
      data: (data) {
        if (data.categories.isEmpty) {
          return const _RetryHint(text: 'Bu sınıf için kategori bulunmuyor.');
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studyPlanProvider(yearNo));
            await ref.read(studyPlanProvider(yearNo).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              _YearHeader(yearNo: yearNo, categories: data.categories),
              const SizedBox(height: 12),
              for (final item in data.categories) ...[
                _StudyCategoryCard(item: item, yearNo: yearNo),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.yearNo, required this.categories});

  final int yearNo;
  final List<FtrStudyPlanCategory> categories;

  @override
  Widget build(BuildContext context) {
    final planned = categories.fold<int>(0, (sum, item) => sum + item.plannedContentCount);
    final published = categories.fold<int>(0, (sum, item) => sum + item.publishedContentCount);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '$yearNo',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$yearNo. Sınıf',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  published > 0
                      ? '$published içerik yayında • $planned içerik müfredatta'
                      : '$planned içerik müfredatta • yayın incelemeleri sürüyor',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyCategoryCard extends StatelessWidget {
  const _StudyCategoryCard({required this.item, required this.yearNo});

  final FtrStudyPlanCategory item;
  final int yearNo;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisualFor(item.name);
    final status = item.publishedContentCount > 0
        ? '${item.publishedContentCount} yayında'
        : item.plannedContentCount > 0
            ? '${item.plannedContentCount} içerik • incelemede'
            : 'İçerik planlanıyor';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(
          '/courses/${item.slug}?name=${Uri.encodeQueryComponent(item.name)}&year=$yearNo',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        if (item.priority == 'core')
                          const _PriorityBadge(text: 'Çekirdek')
                        else if (item.priority == 'support')
                          const _PriorityBadge(text: 'Destek'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(status, style: Theme.of(context).textTheme.bodySmall),
                    if ((item.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.primary700,
          ),
        ),
      );
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
              onTap: () => context.push(
                '/courses/${item.slug}?name=${Uri.encodeQueryComponent(item.name)}',
              ),
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
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description?.trim().isNotEmpty == true
                                ? item.description!
                                : _fallbackDescription(item.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.count}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
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
    if (items.isEmpty) {
      return const Center(child: Text('Henüz yayınlanmış yeni içerik yok.'));
    }
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
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.isQuiz
                    ? Icons.quiz_outlined
                    : item.premium
                        ? Icons.workspace_premium_outlined
                        : Icons.menu_book_outlined,
                color: item.premium ? AppColors.premium : AppColors.primary600,
              ),
            ),
            title: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(routeForContent(item)),
          ),
        );
      },
    );
  }
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.text, required this.onRetry});
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
}

class _RetryHint extends StatelessWidget {
  const _RetryHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}
