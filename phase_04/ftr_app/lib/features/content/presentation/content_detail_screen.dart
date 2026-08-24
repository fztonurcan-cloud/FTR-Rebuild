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
              onPressed: () => ref.invalidate(favoriteStateProvider(contentId)),
              icon: const Icon(Icons.bookmark_border_rounded),
            ),
            data: (isFavorite) => IconButton(
              tooltip: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
              onPressed: () => _toggleFavorite(context, ref, user != null, isFavorite),
              icon: Icon(
                isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Beğen',
            onPressed: () => _toggleFavorite(
              context,
              ref,
              user != null,
              favorite.value ?? false,
            ),
            icon: Icon(
              (favorite.value ?? false) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Paylaş',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaşım bağlantısı yayın sürümünde etkinleştirilecek.')),
              );
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('İçerik şu anda yüklenemedi.')),
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

  bool get isExercise {
    final value = '${item.category} ${item.title}'.toLowerCase();
    return value.contains('egzersiz');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = isExercise
        ? const ['Açıklama', 'Uygulama', 'Videolar', 'Kaynaklar']
        : const ['İçerik', 'Videolar', 'Görseller', 'Kaynaklar'];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 7),
                if (item.premium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4DC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.premium),
                        SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9E6A00)),
                        ),
                      ],
                    ),
                  ),
                if (item.summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(item.summary, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorColor: AppColors.primary600,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.border,
            tabs: [for (final tab in tabs) Tab(text: tab)],
          ),
          Expanded(
            child: TabBarView(
              children: isExercise
                  ? [
                      _ExerciseOverviewTab(item: item),
                      _BodyTab(item: item, userSignedIn: userSignedIn),
                      _MediaTab(assets: item.assets.where((asset) => asset.isVideo).toList()),
                      _SourcesTab(sources: item.sources),
                    ]
                  : [
                      _BodyTab(item: item, userSignedIn: userSignedIn),
                      _MediaTab(assets: item.assets.where((asset) => asset.isVideo).toList()),
                      _MediaTab(assets: item.assets.where((asset) => asset.isImage).toList()),
                      _SourcesTab(sources: item.sources),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOverviewTab extends StatelessWidget {
  const _ExerciseOverviewTab({required this.item});
  final FtrContent item;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(Icons.fitness_center_rounded, size: 54, color: AppColors.primary600),
            ),
          ),
          const SizedBox(height: 18),
          Text('Amaç', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 7),
          Text(
            item.summary.trim().isEmpty
                ? 'Egzersizin amacı ve uygulama bilgileri içerik incelemesi tamamlandıkça burada gösterilir.'
                : item.summary,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          const _SafetyNote(),
        ],
      );
}

class _BodyTab extends ConsumerWidget {
  const _BodyTab({required this.item, required this.userSignedIn});
  final FtrContent item;
  final bool userSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = userSignedIn
        ? ref.watch(contentProgressProvider(item.id))
        : const AsyncData(0.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        if (item.hasAccess)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: item.bodyHtml == null || item.bodyHtml!.trim().isEmpty
                  ? const Text('İçerik gövdesi henüz yeni sisteme taşınmadı.')
                  : Html(data: item.bodyHtml!),
            ),
          )
        else
          _LockedContentCard(item: item),
        if (userSignedIn && item.hasAccess) ...[
          const SizedBox(height: 14),
          progress.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (value) => _ProgressCard(contentId: item.id, value: value),
          ),
        ],
        if (item.premium) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/premium'),
            icon: Icon(item.hasAccess ? Icons.workspace_premium_rounded : Icons.lock_open_rounded),
            label: Text(item.hasAccess ? 'Premium üyeliği yönet' : 'İçeriğin devamını aç'),
          ),
        ],
      ],
    );
  }
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
                    child: Text('Çalışma ilerlemesi', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('%${(value * 100).round()}'),
                ],
              ),
              const SizedBox(height: 9),
              LinearProgressIndicator(value: value.clamp(0.0, 1.0), minHeight: 6),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final next = value >= 1 ? 0.0 : 1.0;
                  await ref.read(userLibraryServiceProvider)?.setProgress(contentId, next);
                  ref.invalidate(contentProgressProvider(contentId));
                },
                icon: Icon(value >= 1 ? Icons.restart_alt_rounded : Icons.check_circle_outline_rounded),
                label: Text(value >= 1 ? 'İlerlemeyi sıfırla' : 'Tamamlandı olarak işaretle'),
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
              const Icon(Icons.lock_outline_rounded, size: 38, color: AppColors.premium),
              const SizedBox(height: 11),
              Text(
                'Bu ders Premium içeriğe dahildir',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 7),
              const Text(
                'İçerik gövdesi yalnızca sunucuda doğrulanmış aktif abonelik olduğunda gönderilir.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _MediaTab extends StatelessWidget {
  const _MediaTab({required this.assets});
  final List<FtrAsset> assets;

  @override
  Widget build(BuildContext context) {
    final ordered = [...assets]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (ordered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Bu bölüm için yayınlanmış medya henüz bulunmuyor.'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: ordered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = ordered[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: asset.isImage
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SignedAssetImage(asset: asset),
                      if (asset.caption != null) ...[
                        const SizedBox(height: 9),
                        Text(asset.caption!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  )
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary50,
                      child: Icon(Icons.play_arrow_rounded, color: AppColors.primary600),
                    ),
                    title: Text(asset.caption ?? 'Video'),
                    subtitle: asset.altText == null ? null : Text(asset.altText!),
                  ),
          ),
        );
      },
    );
  }
}

class _SourcesTab extends StatelessWidget {
  const _SourcesTab({required this.sources});
  final List<FtrSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Bu içerik için kullanıcıya açık kaynak listesi henüz bulunmuyor.'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      itemCount: sources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final source = sources[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  source.verificationStatus == 'verified'
                      ? Icons.verified_outlined
                      : Icons.menu_book_outlined,
                  color: source.verificationStatus == 'verified'
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(source.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (source.publisher != null || source.publicationYear != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (source.publisher != null) source.publisher!,
                            if (source.publicationYear != null) source.publicationYear.toString(),
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
        );
      },
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
          if (url == null || snapshot.hasError) return const _AssetUnavailable();
          return Semantics(
            label: widget.asset.altText ?? widget.asset.caption ?? 'Ders görseli',
            image: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AssetUnavailable(),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.primary50,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
            SizedBox(height: 7),
            Text('Görsel şu anda yüklenemiyor.'),
          ],
        ),
      );
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

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
            Icon(Icons.health_and_safety_outlined, color: AppColors.primary600),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Egzersiz bilgileri genel eğitim amaçlıdır. Uygulama ayrıntıları içerik güvenlik incelemesine göre gösterilir.',
              ),
            ),
          ],
        ),
      );
}
