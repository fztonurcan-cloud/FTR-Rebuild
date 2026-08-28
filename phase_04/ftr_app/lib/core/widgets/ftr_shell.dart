import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class FtrShell extends StatelessWidget {
  const FtrShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  int get selectedIndex {
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/favorites')) return 2;
    if (location.startsWith('/notes')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const paths = ['/', '/courses', '/favorites', '/notes', '/profile'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;

        if (!useRail) {
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
              Container(
                width: 270,
                color: AppColors.surface,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(22, 20, 18, 22),
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
                        child: NavigationRail(
                          extended: true,
                          minExtendedWidth: 270,
                          selectedIndex: selectedIndex,
                          onDestinationSelected: (index) =>
                              context.go(paths[index]),
                          groupAlignment: -1,
                          leading: const SizedBox(height: 8),
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon: Icon(Icons.home),
                              label: Text('Ana Sayfa'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.menu_book_outlined),
                              selectedIcon: Icon(Icons.menu_book),
                              label: Text('Dersler'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.favorite_border),
                              selectedIcon: Icon(Icons.favorite),
                              label: Text('Favorilerim'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.note_alt_outlined),
                              selectedIcon: Icon(Icons.note_alt),
                              label: Text('Notlarım'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.person_outline),
                              selectedIcon: Icon(Icons.person),
                              label: Text('Profil'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
