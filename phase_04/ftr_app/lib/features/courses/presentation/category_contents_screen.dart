import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';

class CategoryContentsScreen extends ConsumerWidget {
  const CategoryContentsScreen({
    required this.categoryName,
    super.key,
  });

  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(categoryContentsProvider(categoryName));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Geri',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Eski FTR arşivindeki konuların modern ve aranabilir kütüphanesi',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          contents.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('İçerikler yüklenemedi: $error'),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Bu kategoride yayınlanmış içerik henüz bulunmuyor.'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push('/content/${item.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary50,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  item.premium
                                      ? Icons.workspace_premium_outlined
                                      : Icons.menu_book_outlined,
                                  color: item.premium
                                      ? AppColors.premium
                                      : AppColors.primary700,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (item.summary.trim().isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        item.summary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
