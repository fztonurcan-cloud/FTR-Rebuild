import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.code, [this.details]);

  final String code;
  final Object? details;

  @override
  String toString() => 'AccountDeletionException($code)';
}

class AuthService {
  const AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStates => _client.auth.onAuthStateChange;

  Stream<User?> get userChanges async* {
    yield _client.auth.currentUser;
    yield* _client.auth.onAuthStateChange.map((state) => state.session?.user);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    final name = displayName?.trim();
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: AppConfig.authRedirectUrl,
      data: name == null || name.isEmpty ? null : {'display_name': name},
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> requestPasswordReset(String email) {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw AuthException('E-posta adresi gerekli.');
    }
    return _client.auth.resetPasswordForEmail(
      normalizedEmail,
      redirectTo: AppConfig.authRedirectUrl,
    );
  }

  Future<UserResponse> updatePassword(String password) {
    if (password.length < 8) {
      throw AuthException('Şifre en az 8 karakter olmalı.');
    }
    return _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> deleteAccount({required String password}) async {
    final user = _client.auth.currentUser;
    final email = user?.email?.trim();
    if (user == null || email == null || email.isEmpty) {
      throw const AccountDeletionException('auth_required');
    }
    if (password.length < 8) {
      throw const AccountDeletionException('password_required');
    }

    // The deletion endpoint requires a token issued in the last five minutes.
    // Re-sign-in with the current account so deletion cannot be triggered only
    // from a long-lived session.
    final reauth = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final freshSession = reauth.session ?? _client.auth.currentSession;
    if (freshSession == null || freshSession.user.id != user.id) {
      throw const AccountDeletionException('reauthentication_required');
    }

    try {
      final response = await _client.functions.invoke(
        'delete-account',
        body: const {'confirm': 'DELETE_MY_FTR_ACCOUNT'},
        headers: {'Authorization': 'Bearer ${freshSession.accessToken}'},
      );
      final data = response.data;
      if (data is! Map || data['deleted'] != true) {
        final code = data is Map ? data['error']?.toString() : null;
        throw AccountDeletionException(code ?? 'delete_failed', data);
      }
    } on FunctionsHttpException catch (error) {
      final details = error.details;
      var code = 'delete_http_${error.status}';
      if (details is Map && details['error'] != null) {
        code = details['error'].toString();
      }
      throw AccountDeletionException(code, details);
    } on FunctionsFetchException catch (error) {
      throw AccountDeletionException('delete_network_error', error.details);
    }

    // The server has already deleted the auth user at this point. A local
    // sign-out failure must not turn a successful deletion into a false error.
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Auth state will be invalidated server-side because the user is gone.
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = currentUser;
    if (user == null) throw AuthException('Oturum bulunamadı.');

    await _client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }
}
