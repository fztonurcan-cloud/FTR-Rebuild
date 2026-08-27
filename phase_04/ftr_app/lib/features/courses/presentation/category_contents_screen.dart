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
    super.key,
  });

  final String categoryName;

  @override
  ConsumerState<CategoryContentsScreen> createState() => _CategoryContentsScreenState();
}

class _CategoryContentsScreenState extends ConsumerState<CategoryContentsScreen> {
  static const _pageSize = 50;

  final ScrollController _scrollController = ScrollController();
  final List<FtrContent> _items = <FtrContent>[];
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future<void>.microtask(_loadInitial);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    if (mounted) {
      setState(() {
        _loadingInitial = true;
        _loadingMore = false;
        _hasMore = true;
        _error = null;
        _items.clear();
      });
    }

    try {
      final page = await ref.read(ftrRepositoryProvider).fetchContentsByCategory(
            widget.categoryName,
            offset: 0,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
        _loadingInitial = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loadingInitial = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingInitial || _loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final page = await ref.read(ftrRepositoryProvider).fetchContentsByCategory(
            widget.categoryName,
            offset: _items.length,
            limit: _pageSize,
          );
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
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadInitial,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
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
                            widget.categoryName,
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
            if (_loadingInitial)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty && _error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('İçerikler yüklenemedi: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _loadInitial, child: const Text('Tekrar dene')),
                      ],
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Bu kategoride yayınlanmış içerik henüz bulunmuyor.'),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                sliver: SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push(routeForContent(item)),
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
                                  item.isQuiz
                                      ? Icons.quiz_outlined
                                      : item.premium
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
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: _loadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _error != null && _hasMore
                          ? OutlinedButton(
                              onPressed: _loadMore,
                              child: const Text('Devamını tekrar yükle'),
                            )
                          : _hasMore
                              ? OutlinedButton(
                                  onPressed: _loadMore,
                                  child: const Text('Daha fazla yükle'),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${_items.length} içerik yüklendi.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
