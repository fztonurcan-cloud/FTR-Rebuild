import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/ftr_study_plan.dart';
import '../theme/app_colors.dart';
import 'category_visuals.dart';

class FtrShell extends ConsumerWidget {
  const FtrShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  int get selectedIndex {
    if (location.startsWith('/courses') ||
        location.startsWith('/content') ||
        location.startsWith('/quiz') ||
        location.startsWith('/search')) {
      return 1;
    }
    if (location.startsWith('/favorites')) return 2;
    if (location.startsWith('/notes')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  String? get selectedCategorySlug {
    final match = RegExp(r'^/courses/([^/?]+)').firstMatch(location);
    return match?.group(1);
  }

  String? get routedContentId {
    final contentMatch = RegExp(r'^/content/([^/?]+)').firstMatch(location);
    if (contentMatch != null) return contentMatch.group(1);
    final quizMatch = RegExp(r'^/quiz/([^/?]+)').firstMatch(location);
    return quizMatch?.group(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const paths = ['/', '/courses', '/favorites', '/notes', '/profile'];
    final routedId = routedContentId;
    final routedContent = routedId == null
        ? null
        : ref.watch(contentDetailProvider(routedId)).value;

    final effectiveCategorySlug = (selectedCategorySlug ??
            routedContent?.categorySlug.trim())
        ?.trim();

    int? activeYear;
    FtrStudyPlanCategory? activeCategory;
    if (effectiveCategorySlug != null && effectiveCategorySlug.isNotEmpty) {
      for (var year = 1; year <= 4; year++) {
        final plan = ref.watch(studyPlanProvider(year)).value;
        if (plan == null) continue;
        for (final category in plan.categories) {
          if (category.slug == effectiveCategorySlug) {
            activeYear = year;
            activeCategory = category;
            break;
          }
        }
        if (activeCategory != null) break;
      }
    }

    final user = ref.watch(authUserProvider).value;
    final breadcrumb = _buildBreadcrumb(
      activeYear: activeYear,
      activeCategory: activeCategory,
      routedTitle: routedContent?.title,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopShell = constraints.maxWidth >= 1040;

        if (!useDesktopShell) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(paths[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Dersler',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Favoriler',
                ),
                NavigationDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  selectedIcon: Icon(Icons.note_alt_rounded),
                  label: 'Notlar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 280,
                child: ColoredBox(
                  color: AppColors.sidebar,
                  child: SafeArea(
                    child: _DesktopSidebar(
                      location: location,
                      selectedCategorySlug: effectiveCategorySlug,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.border),
              Expanded(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      _DesktopTopBar(
                        breadcrumb: breadcrumb,
                        avatarLabel: _avatarLabel(user?.email),
                        onSearch: () => context.go('/search'),
                        onNotifications: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Yeni bildirimin yok.')),
                          );
                        },
                      ),
                      Container(height: 1, color: AppColors.border),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _buildBreadcrumb({
    required int? activeYear,
    required FtrStudyPlanCategory? activeCategory,
    required String? routedTitle,
  }) {
    if (location == '/') return const ['Ana Sayfa'];
    if (location.startsWith('/favorites')) return const ['Favorilerim'];
    if (location.startsWith('/notes')) return const ['Notlarım'];
    if (location.startsWith('/profile')) return const ['Ayarlar'];
    if (location.startsWith('/search')) return const ['Derslerde Ara'];

    final parts = <String>[];
    if (activeYear != null) parts.add('$activeYear. SINIF');
    if (activeCategory != null) parts.add(activeCategory.name);
    if (routedTitle != null && routedTitle.trim().isNotEmpty) {
      parts.add(routedTitle.trim());
    }
    if (parts.isNotEmpty) return parts;
    if (location.startsWith('/quiz')) return const ['Sınavlar'];
    return const ['Dersler'];
  }

  String _avatarLabel(String? email) {
    final value = email?.trim();
    if (value == null || value.isEmpty) return 'FTR';
    final local = value.split('@').first.trim();
    if (local.isEmpty) return 'FTR';
    final chunks = local
        .split(RegExp(r'[._\-\s]+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (chunks.length >= 2) {
      return '${chunks.first[0]}${chunks[1][0]}'.toUpperCase();
    }
    return local.substring(0, local.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.breadcrumb,
    required this.avatarLabel,
    required this.onSearch,
    required this.onNotifications,
  });

  final List<String> breadcrumb;
  final String avatarLabel;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _Breadcrumb(parts: breadcrumb),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 6,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Material(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: onSearch,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 22,
                                color: AppColors.textPrimary,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Derslerde ara...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              IconButton(
                tooltip: 'Bildirimler',
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary600, AppColors.primary700],
                  ),
                ),
                child: Text(
                  avatarLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var index = 0; index < parts.length; index++) ...[
          if (index > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '/',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          Flexible(
            child: Text(
              parts[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: index == 0
                    ? AppColors.primary500
                    : index == parts.length - 1
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: index == 0 ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.location,
    required this.selectedCategorySlug,
  });

  final String location;
  final String? selectedCategorySlug;

  bool _active(String path) {
    if (path == '/') return location == '/';
    return location.startsWith(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandHeader(),
        Container(height: 1, color: AppColors.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
            children: [
              _SideNavTile(
                icon: Icons.home_outlined,
                label: 'Ana Sayfa',
                selected: _active('/'),
                onTap: () => context.go('/'),
              ),
              const SizedBox(height: 5),
              for (var year = 1; year <= 4; year++)
                _YearCurriculumSection(
                  key: ValueKey('year-$year-$selectedCategorySlug'),
                  yearNo: year,
                  selectedCategorySlug: selectedCategorySlug,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Container(height: 1, color: AppColors.border),
              ),
              _SideNavTile(
                icon: Icons.ballot_outlined,
                label: 'Sınavlar',
                selected: _active('/quiz'),
                onTap: () => context.go('/courses'),
              ),
              _SideNavTile(
                icon: Icons.bookmark_border_rounded,
                label: 'Favorilerim',
                selected: _active('/favorites'),
                onTap: () => context.go('/favorites'),
              ),
              _SideNavTile(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notlarım',
                selected: _active('/notes'),
                onTap: () => context.go('/notes'),
              ),
              _SideNavTile(
                icon: Icons.settings_outlined,
                label: 'Ayarlar',
                selected: _active('/profile'),
                onTap: () => context.go('/profile'),
              ),
              _SideNavTile(
                icon: Icons.help_outline_rounded,
                label: 'Yardım',
                selected: false,
                onTap: () => context.push('/faq'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary500, AppColors.primary700],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: .22),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.accessibility_new_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FTR Akademi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fizyoterapi & Rehabilitasyon',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearCurriculumSection extends ConsumerWidget {
  const _YearCurriculumSection({
    required this.yearNo,
    required this.selectedCategorySlug,
    super.key,
  });

  final int yearNo;
  final String? selectedCategorySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(studyPlanProvider(yearNo));

    return plan.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Row(
          children: [
            Text(
              '$yearNo. SINIF',
              style: const TextStyle(
                color: AppColors.primary500,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: LinearProgressIndicator(minHeight: 1.5)),
          ],
        ),
      ),
      error: (_, __) => _YearLabel(yearNo: yearNo),
      data: (studyPlan) {
        final categories = studyPlan.categories;
        final activeYear = selectedCategorySlug != null &&
            categories.any((item) => item.slug == selectedCategorySlug);

        if (categories.isEmpty) return _YearLabel(yearNo: yearNo);

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: activeYear ||
                (selectedCategorySlug == null && yearNo == 1),
            minTileHeight: 44,
            tilePadding: const EdgeInsets.symmetric(horizontal: 11),
            childrenPadding: const EdgeInsets.only(bottom: 5),
            iconColor: AppColors.textPrimary,
            collapsedIconColor: AppColors.textSecondary,
            dense: true,
            title: Text(
              '$yearNo. SINIF',
              style: const TextStyle(
                color: AppColors.primary500,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            children: [
              for (final category in categories)
                _CourseTile(
                  yearNo: yearNo,
                  category: category,
                  selected: category.slug == selectedCategorySlug,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _YearLabel extends StatelessWidget {
  const _YearLabel({required this.yearNo});

  final int yearNo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Text(
          '$yearNo. SINIF',
          style: const TextStyle(
            color: AppColors.primary500,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      );
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.yearNo,
    required this.category,
    required this.selected,
  });

  final int yearNo;
  final FtrStudyPlanCategory category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisualFor(category.name);
    final child = InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: () {
        final name = Uri.encodeQueryComponent(category.name);
        context.go('/courses/${category.slug}?name=$name&year=$yearNo');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 9, 10, 9),
        child: Row(
          children: [
            Icon(
              visual.icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        clipBehavior: Clip.antiAlias,
        child: selected
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.primary700, AppColors.primary600],
                  ),
                ),
                child: child,
              )
            : child,
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  const _SideNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? AppColors.primary100 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected
                      ? AppColors.primary500
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
