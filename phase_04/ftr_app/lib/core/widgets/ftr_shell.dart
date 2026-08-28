import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../domain/models/ftr_study_plan.dart';
import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const paths = ['/', '/courses', '/favorites', '/notes', '/profile'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopShell = constraints.maxWidth >= 900;

        if (!useDesktopShell) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(paths[index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Dersler',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Favoriler',
                ),
                NavigationDestination(
                  icon: Icon(Icons.note_alt_outlined),
                  selectedIcon: Icon(Icons.note_alt),
                  label: 'Notlar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
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
                  color: AppColors.surface,
                  child: SafeArea(
                    child: _DesktopSidebar(
                      location: location,
                      selectedCategorySlug: selectedCategorySlug,
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopBar(onSearch: () => context.go('/search')),
                    const Divider(height: 1),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onSearch,
                  child: IgnorePointer(
                    child: TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Derslerde ara...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 22),
              IconButton(
                tooltip: 'Notlarım',
                onPressed: () => context.go('/notes'),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primary700,
                foregroundColor: Colors.white,
                child: Text(
                  'FTR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
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
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 16, 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary100,
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: AppColors.primary600,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FTR Akademi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fizyoterapi & Rehabilitasyon',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
            children: [
              _SideNavTile(
                icon: Icons.home_outlined,
                label: 'Ana Sayfa',
                selected: _active('/'),
                onTap: () => context.go('/'),
              ),
              const SizedBox(height: 7),
              for (var year = 1; year <= 4; year++)
                _YearCurriculumSection(
                  key: ValueKey('year-$year-$selectedCategorySlug'),
                  yearNo: year,
                  selectedCategorySlug: selectedCategorySlug,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Divider(height: 1),
              ),
              _SideNavTile(
                icon: Icons.quiz_outlined,
                label: 'Dersler & Sınavlar',
                selected: _active('/courses') ||
                    _active('/content') ||
                    _active('/quiz'),
                onTap: () => context.go('/courses'),
              ),
              _SideNavTile(
                icon: Icons.favorite_border_rounded,
                label: 'Favorilerim',
                selected: _active('/favorites'),
                onTap: () => context.go('/favorites'),
              ),
              _SideNavTile(
                icon: Icons.note_alt_outlined,
                label: 'Notlarım',
                selected: _active('/notes'),
                onTap: () => context.go('/notes'),
              ),
              _SideNavTile(
                icon: Icons.person_outline_rounded,
                label: 'Profil & Ayarlar',
                selected: _active('/profile'),
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            Text(
              '$yearNo. SINIF',
              style: const TextStyle(
                color: AppColors.primary600,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: LinearProgressIndicator(minHeight: 2)),
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
            tilePadding: const EdgeInsets.symmetric(horizontal: 10),
            childrenPadding: const EdgeInsets.only(bottom: 5),
            iconColor: AppColors.primary600,
            collapsedIconColor: AppColors.textSecondary,
            title: Text(
              '$yearNo. SINIF',
              style: const TextStyle(
                color: AppColors.primary600,
                fontWeight: FontWeight.w800,
                fontSize: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Text(
          '$yearNo. SINIF',
          style: const TextStyle(
            color: AppColors.primary600,
            fontWeight: FontWeight.w800,
            fontSize: 14,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? AppColors.primary700 : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () {
            final name = Uri.encodeQueryComponent(category.name);
            context.go('/courses/${category.slug}?name=$name&year=$yearNo');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 17,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
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
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary600
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
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
