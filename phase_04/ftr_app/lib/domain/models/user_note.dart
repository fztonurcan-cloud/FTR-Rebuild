class UserNote {
  const UserNote({
    required this.id,
    required this.body,
    required this.updatedAt,
    this.contentId,
    this.contentTitle,
  });

  final String id;
  final String body;
  final DateTime updatedAt;
  final String? contentId;
  final String? contentTitle;

  factory UserNote.fromMap(Map<String, dynamic> map) => UserNote(
        id: map['note_id'].toString(),
        body: (map['body'] as String?) ?? '',
        updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
        contentId: map['content_id']?.toString(),
        contentTitle: map['content_title'] as String?,
      );
}
