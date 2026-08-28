import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/content_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../domain/models/ftr_asset.dart';
import '../../../domain/models/ftr_content.dart';
import '../../../domain/models/ftr_source.dart';

class ContentDetailScreen extends ConsumerWidget {
  const ContentDetailScreen({required this.contentId, super.key});
  final String contentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(contentDetailProvider(contentId));
    final user = ref.watch(authUserProvider).value;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1040;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Ders'),
              actions: [
                _FavoriteIconButton(
                  contentId: contentId,
                  signedIn: user != null,
                ),
                IconButton(
                  tooltip: 'Notlarım',
                  onPressed: () => user == null
                      ? context.push('/auth')
                      : context.push('/notes'),
                  icon: const Icon(Icons.sticky_note_2_outlined),
                ),
              ],
            ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('İçerik şu anda yüklenemedi.')),
        data: (item) {
          if (item == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('İçerik bulunamadı veya erişim yetkin yok.'),
              ),
            );
          }
          return _DetailBody(item: item, userSignedIn: user != null);
        },
      ),
    );
  }
}

class _FavoriteIconButton extends ConsumerWidget {
  const _FavoriteIconButton({
    required this.contentId,
    required this.signedIn,
  });

  final String contentId;
  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = signedIn
        ? ref.watch(favoriteStateProvider(contentId))
        : const AsyncData(false);

    return favorite.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(13),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => IconButton(
        tooltip: 'Favori durumunu yenile',
        onPressed: () => ref.invalidate(favoriteStateProvider(contentId)),
        icon: const Icon(Icons.bookmark_border_rounded),
      ),
      data: (isFavorite) => IconButton(
        tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
        onPressed: () async {
          if (!signedIn) {
            await context.push('/auth');
            return;
          }
          final service = ref.read(userLibraryServiceProvider);
          if (service == null) return;
          try {
            if (isFavorite) {
              await service.removeFavorite(contentId);
            } else {
              await service.addFavorite(contentId);
            }
            ref.invalidate(favoriteStateProvider(contentId));
            ref.invalidate(favoritesProvider);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favori işlemi tamamlanamadı.')),
              );
            }
          }
        },
        icon: Icon(
          isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: isFavorite ? AppColors.primary500 : null,
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.item, required this.userSignedIn});
  final FtrContent item;
  final bool userSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = userSignedIn
        ? ref.watch(contentProgressProvider(item.id))
        : const AsyncData(0.0);
    final hasFreePreview = !item.hasAccess &&
        item.premium &&
        item.bodyHtml != null &&
        item.bodyHtml!.trim().isNotEmpty;
    final canRenderBody = item.hasAccess || hasFreePreview;
    final images = item.assets.where((asset) => asset.isImage).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final isDesktop = MediaQuery.sizeOf(context).width >= 1040;

    int? yearNo;
    if (item.categorySlug.trim().isNotEmpty) {
      for (var year = 1; year <= 4; year++) {
        final plan = ref.watch(studyPlanProvider(year)).value;
        if (plan == null) continue;
        if (plan.categories.any((category) => category.slug == item.categorySlug)) {
          yearNo = year;
          break;
        }
      }
    }

    AsyncValue<List<FtrContent>> siblings = const AsyncData(<FtrContent>[]);
    if (yearNo != null && item.categorySlug.trim().isNotEmpty) {
      siblings = ref.watch(
        curriculumCategoryContentsProvider(
          (yearNo: yearNo, categorySlug: item.categorySlug),
        ),
      );
    }

    FtrContent? previous;
    FtrContent? next;
    FtrContent? quizTarget;
    final siblingItems = siblings.value ?? const <FtrContent>[];
    final lessonItems = siblingItems.where((content) => !content.isQuiz).toList();
    final currentIndex = lessonItems.indexWhere((content) => content.id == item.id);
    if (currentIndex > 0) previous = lessonItems[currentIndex - 1];
    if (currentIndex >= 0 && currentIndex + 1 < lessonItems.length) {
      next = lessonItems[currentIndex + 1];
    }
    for (final content in siblingItems) {
      if (content.isQuiz) {
        quizTarget = content;
        break;
      }
    }

    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LessonHeader(
          item: item,
          userSignedIn: userSignedIn,
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 14),
        _LessonTabs(
          item: item,
          userSignedIn: userSignedIn,
          quizTarget: quizTarget,
        ),
        const SizedBox(height: 28),
        if (hasFreePreview) ...[
          const _FreePreviewNotice(),
          const SizedBox(height: 20),
        ],
        if (canRenderBody)
          _LessonReader(
            bodyHtml: item.bodyHtml ?? '',
            images: images,
          )
        else
          _LockedContentCard(item: item),
        if (item.sources.isNotEmpty) ...[
          const SizedBox(height: 34),
          const _SectionTitle(
            icon: Icons.menu_book_outlined,
            title: 'Kaynaklar',
          ),
          const SizedBox(height: 12),
          _SourcesSection(sources: item.sources),
        ],
        if (userSignedIn && item.hasAccess) ...[
          const SizedBox(height: 24),
          progress.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (value) =>
                _ProgressCard(contentId: item.id, value: value),
          ),
        ],
        if (item.premium && !item.hasAccess) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/premium'),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Premium ile dersin tamamını aç'),
          ),
        ],
        const SizedBox(height: 28),
        _LessonFooterNavigation(previous: previous, next: next),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 36 : 18,
        isDesktop ? 34 : 12,
        isDesktop ? 36 : 18,
        36,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: page,
          ),
        ),
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.item,
    required this.userSignedIn,
    required this.isDesktop,
  });

  final FtrContent item;
  final bool userSignedIn;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: isDesktop
                    ? Theme.of(context).textTheme.headlineLarge
                    : Theme.of(context).textTheme.headlineMedium,
              ),
              if (item.premium) ...[
                const SizedBox(height: 10),
                const _PremiumBadge(),
              ],
            ],
          ),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 16),
          _FavoriteIconButton(
            contentId: item.id,
            signedIn: userSignedIn,
          ),
          IconButton(
            tooltip: 'Notlarım',
            onPressed: () => userSignedIn
                ? context.push('/notes')
                : context.push('/auth'),
            icon: const Icon(Icons.sticky_note_2_outlined),
          ),
        ],
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary700),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 14,
              color: AppColors.premium,
            ),
            SizedBox(width: 5),
            Text(
              'Premium Ders',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
}

class _LessonTabs extends StatelessWidget {
  const _LessonTabs({
    required this.item,
    required this.userSignedIn,
    required this.quizTarget,
  });

  final FtrContent item;
  final bool userSignedIn;
  final FtrContent? quizTarget;

  String get primaryLabel {
    final category = item.category.trim();
    if (category.isEmpty || category.length > 18) return 'Anlatım';
    return category;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 9,
      children: [
        _LessonTabButton(label: primaryLabel, selected: true),
        _LessonTabButton(
          label: 'Notlarım',
          icon: Icons.edit_note_rounded,
          onTap: () => userSignedIn
              ? context.push('/notes')
              : context.push('/auth'),
        ),
        _LessonTabButton(
          label: 'Kaynaklar',
          icon: Icons.menu_book_outlined,
          enabled: item.sources.isNotEmpty,
          onTap: item.sources.isEmpty
              ? null
              : () => _showSources(context, item.sources),
        ),
        _LessonTabButton(
          label: 'Quiz',
          icon: Icons.quiz_outlined,
          enabled: quizTarget != null,
          onTap: quizTarget == null
              ? null
              : () => context.push(routeForContent(quizTarget!)),
        ),
      ],
    );
  }

  void _showSources(BuildContext context, List<FtrSource> sources) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceRaised,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kaynaklar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _SourcesSection(sources: sources),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTabButton extends StatelessWidget {
  const _LessonTabButton({
    required this.label,
    this.icon,
    this.selected = false,
    this.enabled = true,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : enabled
            ? AppColors.textPrimary
            : AppColors.textMuted;

    return Material(
      color: selected ? AppColors.primary700 : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.primary600 : AppColors.borderStrong,
            ),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary600, AppColors.primary700],
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonReader extends StatelessWidget {
  const _LessonReader({
    required this.bodyHtml,
    required this.images,
  });

  final String bodyHtml;
  final List<FtrAsset> images;

  @override
  Widget build(BuildContext context) {
    final sections = _splitHtmlIntoLearningSections(bodyHtml);
    final isWide = MediaQuery.sizeOf(context).width >= 1040;

    if (sections.isEmpty && images.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('İçerik gövdesi henüz yeni sisteme taşınmadı.'),
        ),
      );
    }

    FtrAsset? heroImage;
    if (isWide && sections.isNotEmpty && images.isNotEmpty) {
      final firstPlacement = _placementIndexForAsset(sections, images.first);
      if (firstPlacement == null || firstPlacement == 0) {
        heroImage = images.first;
      }
    }

    if (isWide && sections.isNotEmpty && heroImage != null) {
      final restSections =
          sections.length > 1 ? sections.sublist(1) : <String>[];
      final restImages = images.where((asset) => asset.id != heroImage!.id).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _HtmlSection(html: sections.first),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InlineLessonImage(asset: heroImage),
                    const SizedBox(height: 18),
                    const _LearningTipCard(),
                  ],
                ),
              ),
            ],
          ),
          if (restSections.isNotEmpty || restImages.isNotEmpty) ...[
            const SizedBox(height: 30),
            ..._buildInterleavedSections(restSections, restImages),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._buildInterleavedSections(sections, images),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _LearningTipCard(),
        ],
      ],
    );
  }
}

class _HtmlSection extends StatelessWidget {
  const _HtmlSection({required this.html});
  final String html;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 2),
      child: Html(data: html),
    );
  }
}

class _InlineLessonImage extends StatelessWidget {
  const _InlineLessonImage({required this.asset});
  final FtrAsset asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.imagePanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9DCE2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SignedAssetImage(asset: asset),
          if ((asset.caption ?? '').trim().isNotEmpty ||
              (asset.altText ?? '').trim().isNotEmpty)
            Container(
              color: AppColors.imagePanel,
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 13),
              child: Text(
                (asset.caption ?? asset.altText ?? '').trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF585E69),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearningTipCard extends StatelessWidget {
  const _LearningTipCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 18, 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary700),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipIcon(),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Öğrenme ipucu: Görseldeki yapıları metindeki başlıklarla eşleştirerek ilerle; böylece konu anlatımı ve görsel hafıza aynı akışta kalır.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      );
}

class _TipIcon extends StatelessWidget {
  const _TipIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary600, AppColors.primary700],
          ),
        ),
        child: const Icon(
          Icons.lightbulb_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      );
}

class _LessonFooterNavigation extends StatelessWidget {
  const _LessonFooterNavigation({required this.previous, required this.next});

  final FtrContent? previous;
  final FtrContent? next;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: previous == null
              ? null
              : () => context.go(routeForContent(previous!)),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Önceki'),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: next == null ? null : () => context.go(routeForContent(next!)),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Sonraki'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.primary500),
          const SizedBox(width: 9),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      );
}

class _FreePreviewNotice extends StatelessWidget {
  const _FreePreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary700),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.visibility_outlined, color: AppColors.primary500),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ücretsiz örnek: Bu bölüm, insan tıbbi/editoryal incelemesinden geçmiş Premium içeriğin sınırlı önizlemesidir.',
              ),
            ),
          ],
        ),
      );
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.contentId, required this.value});
  final String contentId;
  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Çalışma ilerlemesi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('%${(value * 100).round()}'),
              ],
            ),
            const SizedBox(height: 9),
            LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 5,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final nextValue = value >= 1 ? 0.0 : 1.0;
                  await ref
                      .read(userLibraryServiceProvider)
                      ?.setProgress(contentId, nextValue);
                  ref.invalidate(contentProgressProvider(contentId));
                },
                icon: Icon(
                  value >= 1
                      ? Icons.restart_alt_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  value >= 1
                      ? 'İlerlemeyi sıfırla'
                      : 'Tamamlandı olarak işaretle',
                ),
              ),
            ),
          ],
        ),
      );
}

class _LockedContentCard extends StatelessWidget {
  const _LockedContentCard({required this.item});
  final FtrContent item;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: AppColors.premium,
            ),
            const SizedBox(height: 12),
            Text(
              'Bu ders Premium içeriğe dahildir',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 7),
            const Text(
              'Tam içerik yalnızca sunucuda doğrulanmış aktif abonelik olduğunda gönderilir.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.sources});
  final List<FtrSource> sources;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < sources.length; index++) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  sources[index].verificationStatus == 'verified'
                      ? Icons.verified_outlined
                      : Icons.menu_book_outlined,
                  color: sources[index].verificationStatus == 'verified'
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sources[index].title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (sources[index].publisher != null ||
                          sources[index].publicationYear != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (sources[index].publisher != null)
                              sources[index].publisher!,
                            if (sources[index].publicationYear != null)
                              sources[index].publicationYear.toString(),
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (index != sources.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _SignedAssetImage extends StatefulWidget {
  const _SignedAssetImage({required this.asset});
  final FtrAsset asset;

  @override
  State<_SignedAssetImage> createState() => _SignedAssetImageState();
}

class _SignedAssetImageState extends State<_SignedAssetImage> {
  late Future<String?> _signedUrlFuture;

  @override
  void initState() {
    super.initState();
    _signedUrlFuture = _createSignedUrl();
  }

  @override
  void didUpdateWidget(covariant _SignedAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.storagePath != widget.asset.storagePath) {
      _signedUrlFuture = _createSignedUrl();
    }
  }

  Future<String?> _createSignedUrl() async {
    final path = widget.asset.storagePath.trim();
    if (path.isEmpty || !AppConfig.hasSupabaseConfiguration) return null;
    return Supabase.instance.client.storage
        .from(AppConfig.contentMediaBucket)
        .createSignedUrl(path, 900);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: _signedUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 360,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final url = snapshot.data;
          if (url == null || snapshot.hasError) {
            return const _AssetUnavailable();
          }
          return Semantics(
            label: widget.asset.altText ??
                widget.asset.caption ??
                'Ders görseli',
            image: true,
            child: Stack(
              children: [
                Container(
                  color: AppColors.imagePanel,
                  constraints: const BoxConstraints(minHeight: 280, maxHeight: 650),
                  alignment: Alignment.center,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const _AssetUnavailable(),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Material(
                    color: AppColors.background,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Görseli büyüt',
                      onPressed: () => _openViewer(context, url),
                      icon: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  void _openViewer(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: .8,
                maxScale: 6,
                child: Center(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                tooltip: 'Kapat',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetUnavailable extends StatelessWidget {
  const _AssetUnavailable();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 220,
        color: const Color(0xFFEDEEF1),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF666D78),
            ),
            SizedBox(height: 7),
            Text(
              'Görsel şu anda yüklenemiyor.',
              style: TextStyle(color: Color(0xFF555C67)),
            ),
          ],
        ),
      );
}

List<Widget> _buildInterleavedSections(
  List<String> sections,
  List<FtrAsset> images,
) {
  if (sections.isEmpty) {
    return [
      for (var i = 0; i < images.length; i++) ...[
        _InlineLessonImage(asset: images[i]),
        if (i != images.length - 1) const SizedBox(height: 22),
      ],
    ];
  }

  final placements = <int, List<FtrAsset>>{};
  final unplaced = <FtrAsset>[];

  for (final image in images) {
    final exactIndex = _placementIndexForAsset(sections, image);
    if (exactIndex == null) {
      unplaced.add(image);
    } else {
      placements.putIfAbsent(exactIndex, () => <FtrAsset>[]).add(image);
    }
  }

  if (unplaced.isNotEmpty) {
    for (var i = 0; i < unplaced.length; i++) {
      var target = (i * sections.length) ~/ unplaced.length;
      if (target >= sections.length) target = sections.length - 1;
      placements.putIfAbsent(target, () => <FtrAsset>[]).add(unplaced[i]);
    }
  }

  final widgets = <Widget>[];
  for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
    widgets.add(_HtmlSection(html: sections[sectionIndex]));
    final sectionImages = placements[sectionIndex] ?? const <FtrAsset>[];
    for (final image in sectionImages) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(_InlineLessonImage(asset: image));
    }
    if (sectionIndex != sections.length - 1) {
      widgets.add(const SizedBox(height: 24));
    }
  }
  return widgets;
}

int? _placementIndexForAsset(List<String> sections, FtrAsset asset) {
  final placement = _normalizeText(asset.placementAfterHeading ?? '');
  if (placement.isEmpty) return null;
  for (var index = 0; index < sections.length; index++) {
    final sectionText = _normalizeText(_stripHtml(sections[index]));
    if (sectionText.contains(placement)) return index;
  }
  return null;
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>', multiLine: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
}

String _normalizeText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _splitHtmlIntoLearningSections(String html) {
  final source = html.trim();
  if (source.isEmpty) return const <String>[];

  final headingRegex = RegExp(
    r'(?=<h[1-4](?:\s|>))',
    caseSensitive: false,
  );
  final headingStarts = headingRegex
      .allMatches(source)
      .map((match) => match.start)
      .where((start) => start > 0)
      .toList();

  if (headingStarts.isNotEmpty) {
    final sections = <String>[];
    var start = 0;
    for (final end in headingStarts) {
      final chunk = source.substring(start, end).trim();
      if (chunk.isNotEmpty) sections.add(chunk);
      start = end;
    }
    final tail = source.substring(start).trim();
    if (tail.isNotEmpty) sections.add(tail);
    if (sections.isNotEmpty) return sections;
  }

  final paragraphEnds = RegExp(
    r'</p>',
    caseSensitive: false,
  ).allMatches(source).map((match) => match.end).toList();

  if (paragraphEnds.length < 4) return <String>[source];

  final sections = <String>[];
  var start = 0;
  for (var i = 1; i < paragraphEnds.length; i += 2) {
    final end = paragraphEnds[i];
    final chunk = source.substring(start, end).trim();
    if (chunk.isNotEmpty) sections.add(chunk);
    start = end;
  }
  if (start < source.length) {
    final tail = source.substring(start).trim();
    if (tail.isNotEmpty) sections.add(tail);
  }
  return sections.isEmpty ? <String>[source] : sections;
}
