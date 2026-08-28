import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/content_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../domain/models/ftr_content.dart';

class CategoryContentsScreen extends ConsumerStatefulWidget {
  const CategoryContentsScreen({
    required this.categoryName,
    required this.categorySlug,
    this.yearNo,
    super.key,
  });

  final String categoryName;
  final String categorySlug;
  final int? yearNo;

  @override
  ConsumerState<CategoryContentsScreen> createState() =>
      _CategoryContentsScreenState();
}

class _CategoryContentsScreenState
    extends ConsumerState<CategoryContentsScreen> {
  static const _pageSize = 50;

  final ScrollController _controller = ScrollController();
  final List<FtrContent> _items = <FtrContent>[];
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    Future<void>.microtask(_reload);
  }

  @override
  void didUpdateWidget(covariant CategoryContentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName ||
        oldWidget.categorySlug != widget.categorySlug ||
        oldWidget.yearNo != widget.yearNo) {
      Future<void>.microtask(_reload);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter < 500) _loadMore();
  }

  Future<List<FtrContent>> _fetchPage(int offset) async {
    final yearNo = widget.yearNo;
    if (yearNo != null && widget.categorySlug.trim().isNotEmpty) {
      final service = ref.read(studyPlanServiceProvider);
      if (service == null) {
        throw StateError('Müfredat servisi kullanılamıyor.');
      }
      return service.fetchCategoryContents(
        yearNo: yearNo,
        categorySlug: widget.categorySlug,
        offset: offset,
        limit: _pageSize,
      );
    }

    return ref.read(ftrRepositoryProvider).fetchContentsByCategory(
          widget.categoryName,
          offset: offset,
          limit: _pageSize,
        );
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _initialLoading = true;
        _loadingMore = false;
        _hasMore = true;
        _error = null;
        _items.clear();
      });
    }

    try {
      final page = await _fetchPage(0);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _initialLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_initialLoading || _loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final page = await _fetchPage(_items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryName.trim().isEmpty
        ? 'Ders İçerikleri'
        : widget.categoryName;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1040;

    final content = RefreshIndicator(
      onRefresh: _reload,
      child: _buildBody(context),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : AppBar(title: Text(title)),
      body: isDesktop
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 30, 36, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.yearNo == null
                                  ? 'Ders anlatımları ve sınav içerikleri'
                                  : '${widget.yearNo}. sınıf • Ders anlatımları ve sınav içerikleri',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/search'),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('İçerikte ara'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_initialLoading) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_items.isEmpty && _error != null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(onRetry: _reload),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(yearNo: widget.yearNo),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width >= 1040 ? 36 : 16,
        14,
        MediaQuery.sizeOf(context).width >= 1040 ? 36 : 16,
        30,
      ),
      itemCount: _items.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ListHeader(
            yearNo: widget.yearNo,
            itemCount: _items.length,
          );
        }
        if (index == _items.length + 1) {
          return _Footer(
            loading: _loadingMore,
            hasMore: _hasMore,
            hasError: _error != null,
            onRetry: _loadMore,
          );
        }

        final item = _items[index - 1];
        return Material(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(routeForContent(item)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.isQuiz
                          ? Icons.quiz_outlined
                          : Icons.menu_book_outlined,
                      color: item.premium
                          ? AppColors.premium
                          : AppColors.primary500,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.summary.trim().isEmpty
                              ? (item.isQuiz ? 'Quiz' : 'Ders anlatımı')
                              : item.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (item.premium)
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 18,
                      color: AppColors.premium,
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
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

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.yearNo, required this.itemCount});
  final int? yearNo;
  final int itemCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary700),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, color: AppColors.primary500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                yearNo == null
                    ? '$itemCount içerik'
                    : '$yearNo. sınıf • $itemCount içerik',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.yearNo});
  final int? yearNo;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 54,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                yearNo == null
                    ? 'Bu derste yayına alınmış içerik henüz bulunmuyor.'
                    : '$yearNo. sınıfta bu ders için yayına alınmış içerik henüz bulunmuyor.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hazır olan ders içerikleri burada görüntülenecek.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 12),
              const Text('İçerikler yüklenemedi.'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.hasMore,
    required this.hasError,
    required this.onRetry,
  });

  final bool loading;
  final bool hasMore;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (hasError && hasMore) {
      return Center(
        child: OutlinedButton(
          onPressed: onRetry,
          child: const Text('Devamını tekrar yükle'),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Tüm içerikler yüklendi.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
