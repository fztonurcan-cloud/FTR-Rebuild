import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/ftr_content.dart';
import '../domain/models/user_note.dart';

class UserLibraryService {
  const UserLibraryService(this._client);

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentUser != null;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException('Bu işlem için giriş yapmalısın.');
    return user;
  }

  Future<List<FtrContent>> fetchFavorites() async {
    if (!isSignedIn) return const [];
    final rows = await _client.rpc('get_my_favorites');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(FtrContent.fromMap)
        .toList();
  }

  Future<bool> isFavorite(String contentId) async {
    if (!isSignedIn) return false;
    final rows = await _client
        .from('favorites')
        .select('content_id')
        .eq('content_id', contentId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> addFavorite(String contentId) async {
    final user = _requireUser();
    await _client.from('favorites').upsert(
      {'user_id': user.id, 'content_id': contentId},
      onConflict: 'user_id,content_id',
    );
  }

  Future<void> removeFavorite(String contentId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('content_id', contentId);
  }


  Future<double> fetchProgress(String contentId) async {
    if (!isSignedIn) return 0;
    final rows = await _client
        .from('user_progress')
        .select('progress')
        .eq('content_id', contentId)
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return 0;
    return (list.first['progress'] as num?)?.toDouble() ?? 0;
  }

  Future<void> setProgress(String contentId, double progress) async {
    final user = _requireUser();
    final value = progress.clamp(0.0, 1.0);
    await _client.from('user_progress').upsert(
      {
        'user_id': user.id,
        'content_id': contentId,
        'progress': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,content_id',
    );
  }


  Future<List<UserNote>> fetchNotes() async {
    if (!isSignedIn) return const [];
    final rows = await _client.rpc('get_my_notes');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(UserNote.fromMap)
        .toList();
  }

  Future<void> createNote({required String body, String? contentId}) async {
    final user = _requireUser();
    final value = body.trim();
    if (value.isEmpty) return;
    await _client.from('notes').insert({
      'user_id': user.id,
      'content_id': contentId,
      'body': value,
    });
  }

  Future<void> updateNote({required String noteId, required String body}) async {
    final user = _requireUser();
    final value = body.trim();
    if (value.isEmpty) return;
    await _client
        .from('notes')
        .update({'body': value, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', noteId)
        .eq('user_id', user.id);
  }

  Future<void> deleteNote(String noteId) async {
    final user = _requireUser();
    await _client.from('notes').delete().eq('id', noteId).eq('user_id', user.id);
  }
}
