import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/providers.dart';
import '../../../domain/models/user_note.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notlarım')),
      floatingActionButton: user.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Not ekle'),
            ),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _LoginRequired(onTap: () => context.push('/auth')),
        data: (account) {
          if (account == null) return _LoginRequired(onTap: () => context.push('/auth'));
          final notes = ref.watch(notesProvider);
          return notes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: OutlinedButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('Notları tekrar yükle'),
              ),
            ),
            data: (items) => items.isEmpty
                ? const Center(child: Text('Henüz not oluşturmadın.'))
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notesProvider);
                      await ref.read(notesProvider.future);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _NoteCard(
                        note: items[index],
                        onEdit: () => _openEditor(context, ref, note: items[index]),
                        onDelete: () => _delete(context, ref, items[index]),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {UserNote? note}) async {
    final controller = TextEditingController(text: note?.body ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(note == null ? 'Yeni not' : 'Notu düzenle', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 5,
              maxLines: 12,
              decoration: const InputDecoration(hintText: 'Notunu yaz…', alignLabelWithHint: true),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      controller.dispose();
      return;
    }

    final body = controller.text;
    controller.dispose();
    final service = ref.read(userLibraryServiceProvider);
    if (service == null || body.trim().isEmpty) return;
    if (note == null) {
      await service.createNote(body: body);
    } else {
      await service.updateNote(noteId: note.id, body: body);
    }
    ref.invalidate(notesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, UserNote note) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (approved != true) return;
    await ref.read(userLibraryServiceProvider)?.deleteNote(note.id);
    ref.invalidate(notesProvider);
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onEdit, required this.onDelete});
  final UserNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((note.contentTitle ?? '').isNotEmpty) ...[
                Text(note.contentTitle!, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
              ],
              Text(note.body),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: onEdit, tooltip: 'Düzenle', icon: const Icon(Icons.edit_outlined)),
                  IconButton(onPressed: onDelete, tooltip: 'Sil', icon: const Icon(Icons.delete_outline)),
                ],
              ),
            ],
          ),
        ),
      );
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notes_outlined, size: 56),
              const SizedBox(height: 14),
              Text('Notlarını hesabında sakla', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Notlarını cihazlar arasında güvenli biçimde eşitlemek için giriş yap.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: const Text('Giriş yap / Hesap oluştur')),
            ],
          ),
        ),
      );
}
