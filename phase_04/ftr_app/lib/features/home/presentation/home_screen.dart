import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/content_route.dart';
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 1040;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 36 : 18,
          isDesktop ? 34 : 16,
          isDesktop ? 36 : 18,
          32,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GreetingHeader(
                    signedIn: user != null,
                    isDesktop: isDesktop,
                    onProfile: () => context.go('/profile'),
                  ),
                  if (!isDesktop) ...[
                    const SizedBox(height: 18),
                    _SearchBar(onTap: () => context.go('/search')),
                  ],
                  const SizedBox(height: 28),
                  _SectionTitle(
                    title: user != null ? 'Çalışmaya devam et' : 'Müfredatı keşfet',
                    action: 'Tüm dersler',
                    onAction: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 12),
                  featured.when(
                    data: (items) => items.isEmpty
                        ? const _EmptyCard(text: 'Henüz gösterilecek bir ders yok.')
                        : _ContinueCard(item: items.first, signedIn: user != null),
                    loading: () => const _LoadingCard(height: 132),
                    error: (_, __) =>
                        const _EmptyCard(text: 'Dersler şu anda yüklenemedi.'),
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Ders Alanları'),
                  const SizedBox(height: 12),
                  categories.when(
                    data: (items) =>
                        _CategoryGrid(items: items.take(12).toList(growable: false)),
                    loading: () => const _LoadingCard(height: 280),
                    error: (_, __) => const _EmptyCard(
                      text: 'Ders alanları şu anda yüklenemedi.',
                    ),
                  ),
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Öne çıkan konular',
                    action: 'Tümünü gör',
                    onAction: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 12),
                  featured.when(
                    data: (items) => _PopularTopics(items: items),
                    loading: () => const _LoadingCard(height: 154),
                    error: (_, __) => const _EmptyCard(
                      text: 'Öne çıkan içerikler yüklenemedi.',
                    ),
                  ),
                  const SizedBox(height: 26),
                  _PremiumStrip(onTap: () => context.push('/premium')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.signedIn,
    required this.isDesktop,
    required this.onProfile,
  });

  final bool signedIn;
  final bool isDesktop;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDesktop ? 'FTR Akademi' : 'Merhaba 👋',
                  style: isDesktop
                      ? Theme.of(context).textTheme.headlineLarge
                      : Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  signedIn
                      ? 'Dört yıllık FTR öğrenme yolunda kaldığın yerden devam et.'
                      : 'Dört yıllık FTR müfredatını ders ders keşfet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (!isDesktop)
            IconButton(
              tooltip: signedIn ? 'Profil' : 'Giriş yap',
              onPressed: onProfile,
              icon: Icon(
                signedIn ? Icons.person_outline_rounded : Icons.login_rounded,
              ),
            ),
        ],
      );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 21,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Ders, hastalık veya egzersiz ara...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text('$action  →'),
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
    final progress = signedIn
        ? ref.watch(contentProgressProvider(item.id))
        : const AsyncData(0.0);
    final value = progress.value ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(routeForContent(item)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary700, Color(0xFF34225D)],
                  ),
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category.trim().isNotEmpty)
                      Text(
                        item.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary500,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    if (item.category.trim().isNotEmpty) const SizedBox(height: 5),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      signedIn ? 'Kaldığın yerden devam et' : 'Dersi incele',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (signedIn) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: value.clamp(0.0, 1.0),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '%${(value * 100).round()}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 11),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Müfredatı keşfet',
                            style: TextStyle(
                              color: AppColors.primary500,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.primary500,
                          ),
                        ],
                      ),
                    ],
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 620
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns >= 4 ? 1.8 : 1.25,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final visual = categoryVisualFor(item.name);
            return Material(
              color: AppColors.surfaceRaised,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push(
                  '/courses/${item.slug}?name=${Uri.encodeQueryComponent(item.name)}',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          visual.icon,
                          color: AppColors.primary500,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    final visible = items.take(6).toList(growable: false);
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = visible[index];
          return SizedBox(
            width: 190,
            child: Material(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push(routeForContent(item)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isQuiz
                            ? Icons.quiz_outlined
                            : Icons.menu_book_outlined,
                        color: item.premium
                            ? AppColors.premium
                            : AppColors.primary500,
                        size: 26,
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
        padding: const EdgeInsets.fromLTRB(18, 17, 16, 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF17132B), Color(0xFF211842)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primary700),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.premium,
              size: 30,
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FTR Akademi Premium',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Dört yıllık ders içeriği, görsel öğrenme ve sınav hazırlığı tek yerde.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('İncele')),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}
