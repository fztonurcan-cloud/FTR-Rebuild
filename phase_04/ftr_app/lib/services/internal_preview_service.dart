import 'package:supabase_flutter/supabase_flutter.dart';

class InternalPreviewService {
  const InternalPreviewService(this._client);

  final SupabaseClient _client;

  Future<dynamic> invoke(
    String action, {
    Map<String, dynamic> payload = const {},
  }) async {
    final session = _client.auth.currentSession;
    final accessToken = session?.accessToken.trim() ?? '';
    if (accessToken.isEmpty) {
      throw StateError('internal_preview_auth_required');
    }

    final response = await _client.functions.invoke(
      'internal-preview',
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
      body: {
        'action': action,
        'payload': payload,
      },
    );
    final data = response.data;
    if (data is Map && data['ok'] == true) return data['data'];
    final code = data is Map ? data['error']?.toString() : null;
    throw StateError(code ?? 'internal_preview_failed');
  }
}
