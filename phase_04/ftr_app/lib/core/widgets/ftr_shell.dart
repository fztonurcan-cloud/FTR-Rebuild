import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FtrShell extends StatelessWidget {
  const FtrShell({required this.location, required this.child, super.key});
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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(paths[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Dersler'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoriler'),
          NavigationDestination(icon: Icon(Icons.note_alt_outlined), selectedIcon: Icon(Icons.note_alt), label: 'Notlar'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
