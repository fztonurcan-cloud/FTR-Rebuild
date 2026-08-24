import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = ref.read(authServiceProvider);
    if (service == null) {
      _show('Canlı Supabase bağlantısı bulunamadı.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await service.updatePassword(_passwordController.text);
      if (!mounted) return;
      _passwordController.clear();
      _confirmController.clear();
      _show('Şifren güncellendi.');
      context.go('/profile');
    } on AuthException catch (error) {
      if (mounted) _show(error.message, isError: true);
    } catch (_) {
      if (mounted) _show('Şifre güncellenemedi. Bağlantıyı yeniden açıp tekrar dene.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni şifre belirle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Icon(Icons.lock_reset_rounded, size: 54, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text('Hesabın için yeni şifre oluştur', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Yeni şifren en az 8 karakter olmalı. Bu ekran yalnız geçerli Supabase recovery bağlantısıyla açılır.'),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Yeni şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) => (value ?? '').length < 8 ? 'Şifre en az 8 karakter olmalı.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) { if (!_loading) _save(); },
                    decoration: const InputDecoration(
                      labelText: 'Yeni şifre tekrar',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                    ),
                    validator: (value) => value != _passwordController.text ? 'Şifreler eşleşmiyor.' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _save,
                      child: Text(_loading ? 'Güncelleniyor…' : 'Şifreyi güncelle'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
