import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _registerMode = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final service = ref.read(authServiceProvider);
    if (service == null) {
      _show('Canlı Supabase bağlantısı bulunamadı.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_registerMode) {
        final response = await service.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          _show('Hesabın oluşturuldu. E-posta adresine gelen doğrulama bağlantısını onayla.');
          setState(() => _registerMode = false);
        } else {
          context.pop();
        }
      } else {
        await service.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) context.pop();
      }
    } on AuthException catch (error) {
      if (mounted) _show(error.message, isError: true);
    } catch (_) {
      if (mounted) _show('Giriş işlemi tamamlanamadı. Tekrar dene.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _sendPasswordReset() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _show('Önce geçerli e-posta adresini yaz.', isError: true);
      return;
    }
    final service = ref.read(authServiceProvider);
    if (service == null) {
      _show('Canlı Supabase bağlantısı bulunamadı.', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await service.requestPasswordReset(email);
      if (mounted) {
        _show('Şifre yenileme bağlantısı e-posta adresine gönderildi.');
      }
    } on AuthException catch (error) {
      if (mounted) _show(error.message, isError: true);
    } catch (_) {
      if (mounted) {
        _show('Şifre yenileme e-postası gönderilemedi. Tekrar dene.', isError: true);
      }
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_registerMode ? 'Hesap oluştur' : 'Giriş yap')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.accessibility_new_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _registerMode ? 'FTR hesabını oluştur' : 'Tekrar hoş geldin',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _registerMode
                  ? 'Favoriler, notlar, ilerleme ve Premium erişimin hesabına bağlı tutulacak.'
                  : 'Favorilerine, notlarına ve Premium içeriğine erişmek için giriş yap.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_registerMode) ...[
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Ad soyad',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (!_registerMode) return null;
                        if (value == null || value.trim().length < 2) {
                          return 'Adını yaz.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Geçerli bir e-posta adresi yaz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_loading) _submit();
                    },
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 8) return 'Şifre en az 8 karakter olmalı.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(_loading
                            ? 'İşleniyor…'
                            : _registerMode
                                ? 'Hesap oluştur'
                                : 'Giriş yap'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (!_registerMode)
              TextButton(
                onPressed: _loading ? null : _sendPasswordReset,
                child: const Text('Şifremi unuttum'),
              ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _registerMode = !_registerMode;
                      }),
              child: Text(_registerMode
                  ? 'Zaten hesabın var mı? Giriş yap'
                  : 'Hesabın yok mu? Ücretsiz hesap oluştur'),
            ),
            const SizedBox(height: 12),
            Text(
              'Uygulamayı hesap oluşturmadan da inceleyebilirsin. Hesap yalnızca kişisel özellikler ve Premium erişim için gerekir.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
