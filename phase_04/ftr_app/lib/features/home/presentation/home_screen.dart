import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/category_visuals.dart';
import '../../../data/providers.dart';
import '../../../domain/models/ftr_category.dart';
import '../../../domain/models/ftr_content.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredContentsProvider);
    final user = ref.watch(authUserProvider).value;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          _GreetingHeader(
            signedIn: user != null,
            onBell: () => context.go('/profile'),
          ),
          const SizedBox(height: 18),
          _SearchBar(onTap: () => context.go('/search')),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'Çalışmaya devam et',
            action: 'Tümünü gör',
            onAction: () => context.go('/courses'),
          ),
          const SizedBox(height: 10),
          featured.when(
            data: (items) => items.isEmpty
                ? const _EmptyCard(text: 'Henüz devam edilecek bir ders yok.')
                : _ContinueCard(item: items.first, signedIn: user != null),
            loading: () => const _LoadingCard(height: 126),
            error: (_, __) => const _EmptyCard(text: 'Dersler şu anda yüklenemedi.'),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Kategoriler'),
          const SizedBox(height: 10),
          categories.when(
            data: (items) => _CategoryGrid(items: items.take(9).toList(growable: false)),
            loading: () => const _LoadingCard(height: 280),
            error: (_, __) => const _EmptyCard(text: 'Kategoriler şu anda yüklenemedi.'),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Popüler Konular',
            action: 'Tümünü gör',
            onAction: () => context.go('/courses'),
          ),
          const SizedBox(height: 10),
          featured.when(
            data: (items) => _PopularTopics(items: items),
            loading: () => const _LoadingCard(height: 130),
            error: (_, __) => const _EmptyCard(text: 'Popüler içerikler yüklenemedi.'),
          ),
          const SizedBox(height: 20),
          _PremiumStrip(onTap: () => context.push('/premium')),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.signedIn, required this.onBell});
  final bool signedIn;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merhaba 👋', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  signedIn ? 'Kaldığın yerden devam edelim.' : 'Bugün ne öğrenmek istersin?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: signedIn ? 'Hesap ve bildirimler' : 'Giriş yap',
            onPressed: onBell,
            icon: Icon(signedIn ? Icons.notifications_none_rounded : Icons.person_outline_rounded),
          ),
        ],
      );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFF4F6F7),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ders, hastalık veya egzersiz ara...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                Icon(Icons.search_rounded, size: 22, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              child: Text('$action ›'),
            ),
        ],
      );
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.item, required this.signedIn});
  final FtrContent item;
  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = signedIn ? ref.watch(contentProgressProvider(item.id)) : const AsyncData(0.0);
    final value = progress.value ?? 0.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/content/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF173C45), Color(0xFF4A6D74)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.accessibility_new_rounded, color: Colors.white70, size: 42),
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Container(
                        width: 29,
                        height: 29,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary700, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      signedIn ? 'Kaldığın yerden devam et' : 'Dersi incele',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: value.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.primary100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text('%${(value * 100).round()}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items});
  final List<FtrCategory> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyCard(text: 'Henüz kategori bulunmuyor.');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.02,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final visual = categoryVisualFor(item.name);
        return Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/courses/${item.slug}?name=${Uri.encodeQueryComponent(item.name)}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 11, 8, 9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: visual.tint.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(visual.icon, color: visual.tint, size: 21),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PopularTopics extends StatelessWidget {
  const _PopularTopics({required this.items});
  final List<FtrContent> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyCard(text: 'Henüz öne çıkan içerik yok.');
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.take(6).length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 132,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/content/${item.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 72,
                      color: AppColors.primary50,
                      alignment: Alignment.center,
                      child: Icon(
                        item.premium ? Icons.workspace_premium_outlined : Icons.health_and_safety_outlined,
                        color: item.premium ? AppColors.premium : AppColors.primary600,
                        size: 31,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Text(
                          item.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumStrip extends StatelessWidget {
  const _PremiumStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary100),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.premium, size: 31),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium ile tüm içeriklere eriş', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Sınavlara hazırlan, bilgini bir adım öne taşı.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('Keşfet')),
          ],
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Card(child: Center(child: CircularProgressIndicator())),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
}
