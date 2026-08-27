import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          authUser.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => _SignedOutCard(onTap: () => context.push('/auth')),
            data: (user) => user == null
                ? _SignedOutCard(onTap: () => context.push('/auth'))
                : _SignedInCard(
                    email: user.email ?? 'FTR kullanıcısı',
                    onSignOut: () async {
                      await ref.read(authServiceProvider)?.signOut();
                    },
                  ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Premium'),
              subtitle: const Text('Aboneliğini görüntüle veya yükselt'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/premium'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notes_outlined),
                  title: const Text('Notlar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notes'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Gizlilik ve hesap'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/account'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Sık Sorulan Sorular'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/faq'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'FTR eğitim amaçlıdır; tanı veya kişiye özel tedavi hizmeti sunmaz.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(child: Icon(Icons.person_outline)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hesabına giriş yap',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Favorilerin, notların, ilerlemen ve Premium erişimin hesabınla senkronize edilir.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.login),
              label: const Text('Giriş yap / Hesap oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.email, required this.onSignOut});

  final String email;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FTR hesabı',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async => onSignOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış yap'),
            ),
          ],
        ),
      ),
    );
  }
}
