import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
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
    final favorite = user == null
        ? const AsyncData(false)
        : ref.watch(favoriteStateProvider(contentId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        actions: [
          favorite.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => IconButton(
              tooltip: 'Favori durumunu yenile',
              onPressed: () => ref.invalidate(favoriteStateProvider(contentId)),
              icon: const Icon(Icons.favorite_border_rounded),
            ),
            data: (isFavorite) => IconButton(
              tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
              onPressed: () =>
                  _toggleFavorite(context, ref, user != null, isFavorite),
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notlarım',
            onPressed: () =>
                user == null ? context.push('/auth') : context.push('/notes'),
            icon: const Icon(Icons.note_alt_outlined),
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

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    bool signedIn,
    bool isFavorite,
  ) async {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        _LessonHeader(item: item),
        const SizedBox(height: 20),
        if (hasFreePreview) ...[
          const _FreePreviewNotice(),
          const SizedBox(height: 16),
        ],
        if (canRenderBody)
          _LessonReader(
            bodyHtml: item.bodyHtml ?? '',
            images: images,
          )
        else
          _LockedContentCard(item: item),
        if (item.sources.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionTitle(
            icon: Icons.menu_book_outlined,
            title: 'Kaynaklar',
          ),
          const SizedBox(height: 12),
          _SourcesSection(sources: item.sources),
        ],
        if (userSignedIn && item.hasAccess) ...[
          const SizedBox(height: 20),
          progress.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (value) =>
                _ProgressCard(contentId: item.id, value: value),
          ),
        ],
        if (item.premium) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/premium'),
            icon: Icon(
              item.hasAccess
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_open_rounded,
            ),
            label: Text(
              item.hasAccess
                  ? 'Premium üyeliği yönet'
                  : 'İçeriğin devamını aç',
            ),
          ),
        ],
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.item});
  final FtrContent item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.category.trim().isNotEmpty)
            Text(
              item.category.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary600,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
          if (item.category.trim().isNotEmpty) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (item.premium) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(10),
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
                        'Premium',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (item.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              item.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
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
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (sections.isEmpty && images.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('İçerik gövdesi henüz yeni sisteme taşınmadı.'),
        ),
      );
    }

    if (isWide && sections.isNotEmpty && images.isNotEmpty) {
      final restSections =
          sections.length > 1 ? sections.sublist(1) : <String>[];
      final restImages =
          images.length > 1 ? images.sublist(1) : <FtrAsset>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _HtmlSection(html: sections.first),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 6,
                child: _InlineLessonImage(asset: images.first),
              ),
            ],
          ),
          if (restSections.isNotEmpty || restImages.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._buildInterleavedSections(restSections, restImages),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildInterleavedSections(sections, images),
    );
  }
}

class _HtmlSection extends StatelessWidget {
  const _HtmlSection({required this.html});
  final String html;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SignedAssetImage(asset: asset),
          if ((asset.caption ?? '').trim().isNotEmpty ||
              (asset.altText ?? '').trim().isNotEmpty)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Text(
                (asset.caption ?? asset.altText ?? '').trim(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
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
          Icon(icon, color: AppColors.primary600),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary100),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.visibility_outlined, color: AppColors.primary600),
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
  Widget build(BuildContext context, WidgetRef ref) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                minHeight: 6,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final next = value >= 1 ? 0.0 : 1.0;
                  await ref
                      .read(userLibraryServiceProvider)
                      ?.setProgress(contentId, next);
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
            ],
          ),
        ),
      );
}

class _LockedContentCard extends StatelessWidget {
  const _LockedContentCard({required this.item});
  final FtrContent item;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 38,
                color: AppColors.premium,
              ),
              const SizedBox(height: 11),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
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
            return const AspectRatio(
              aspectRatio: 4 / 3,
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
            child: Container(
              color: Colors.white,
              constraints: const BoxConstraints(minHeight: 180),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const _AssetUnavailable(),
                ),
              ),
            ),
          );
        },
      );
}

class _AssetUnavailable extends StatelessWidget {
  const _AssetUnavailable();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 180,
        color: AppColors.primary50,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 7),
            Text('Görsel şu anda yüklenemiyor.'),
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
        if (i != images.length - 1) const SizedBox(height: 18),
      ],
    ];
  }

  final placements = <int, List<FtrAsset>>{};
  if (images.isNotEmpty) {
    for (var i = 0; i < images.length; i++) {
      var target = (i * sections.length) ~/ images.length;
      if (target >= sections.length) target = sections.length - 1;
      placements.putIfAbsent(target, () => <FtrAsset>[]).add(images[i]);
    }
  }

  final widgets = <Widget>[];
  for (var sectionIndex = 0;
      sectionIndex < sections.length;
      sectionIndex++) {
    widgets.add(_HtmlSection(html: sections[sectionIndex]));
    final sectionImages = placements[sectionIndex] ?? const <FtrAsset>[];
    for (final image in sectionImages) {
      widgets.add(const SizedBox(height: 14));
      widgets.add(_InlineLessonImage(asset: image));
    }
    if (sectionIndex != sections.length - 1) {
      widgets.add(const SizedBox(height: 18));
    }
  }
  return widgets;
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
