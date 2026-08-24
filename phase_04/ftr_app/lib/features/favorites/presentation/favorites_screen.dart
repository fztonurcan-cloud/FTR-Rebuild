import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favoriler', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Expanded(
              child: authUser.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _LoginRequired(onTap: () => context.push('/auth')),
                data: (user) {
                  if (user == null) return _LoginRequired(onTap: () => context.push('/auth'));
                  final favorites = ref.watch(favoritesProvider);
                  return favorites.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _ErrorState(
                      message: 'Favoriler yüklenemedi.',
                      onRetry: () => ref.invalidate(favoritesProvider),
                    ),
                    data: (items) {
                      if (items.isEmpty) return const _EmptyFavorites();
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(favoritesProvider);
                          await ref.read(favoritesProvider.future);
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.favorite)),
                                title: Text(item.title),
                                subtitle: Text(item.category.isEmpty ? item.summary : item.category),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/content/${item.id}'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 56),
            SizedBox(height: 12),
            Text('Henüz favori eklemedin.'),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      );
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Favorilerini hesabında sakla', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Cihaz değiştirsen bile kayıtlarının korunması için giriş yap.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onTap, child: const Text('Giriş yap / Hesap oluştur')),
          ],
        ),
      ),
    );
  }
}
