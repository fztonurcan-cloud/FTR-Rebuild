import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/providers.dart';
import '../../../services/auth_service.dart';

class AccountPrivacyScreen extends ConsumerWidget {
  const AccountPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik ve hesap')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Veri güvenliği'),
                  subtitle: const Text('Kişisel kayıtlar kullanıcı hesabına bağlı ve RLS ile korunur.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Gizlilik politikası'),
                  subtitle: const Text('Yayın öncesi son metin ve URL eklenecek.'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Hesap', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (user == null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Giriş yap'),
                subtitle: const Text('Hesap ayarlarını yönetmek için giriş yap.'),
                onTap: () => context.push('/auth'),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                title: Text('Hesabımı kalıcı olarak sil', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                subtitle: const Text('Profil, favoriler, notlar, ilerleme ve uygulama hesabına bağlı kayıtlar silinir.'),
                onTap: () => _confirmDelete(context, ref),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmController = TextEditingController();
    final passwordController = TextEditingController();
    var obscurePassword = true;

    final confirmation = await showDialog<_DeleteAccountConfirmation>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Hesabı kalıcı olarak sil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu işlem geri alınamaz. Güvenlik için şifreni yeniden gir ve aşağıya SİL yaz.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                autofocus: true,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Mevcut şifre',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                    icon: Icon(
                      obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Onay için SİL yaz'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final typed = confirmController.text.trim().toUpperCase();
                final password = passwordController.text;
                if (typed != 'SİL' || password.length < 8) return;
                Navigator.pop(
                  dialogContext,
                  _DeleteAccountConfirmation(password: password),
                );
              },
              child: const Text('Hesabı sil'),
            ),
          ],
        ),
      ),
    );

    confirmController.dispose();
    passwordController.dispose();
    if (confirmation == null || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final service = ref.read(authServiceProvider);
      if (service == null) {
        throw const AccountDeletionException('service_unavailable');
      }
      await service.deleteAccount(password: confirmation.password);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesabın ve hesaba bağlı verilerin silindi.')),
      );
    } on AuthException {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifren doğrulanamadı. Lütfen tekrar dene.')),
      );
    } on AccountDeletionException catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final message = switch (error.code) {
        'active_google_play_subscription' =>
          'Google Play aboneliğinin otomatik yenilenmesi açık. Önce Play Store’dan aboneliği iptal et, sonra tekrar dene.',
        'reauthentication_required' =>
          'Güvenlik doğrulaması yenilenemedi. Şifreni tekrar girerek yeniden dene.',
        'delete_network_error' =>
          'Sunucuya ulaşılamadı. Hesabın silinmedi; bağlantını kontrol edip tekrar dene.',
        _ => 'Hesap silme işlemi tamamlanamadı. Hesabın silinmedi.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap silinemedi. Lütfen tekrar dene.')),
      );
    }
  }

}

class _DeleteAccountConfirmation {
  const _DeleteAccountConfirmation({required this.password});

  final String password;
}

