class FtrSource {
  const FtrSource({
    required this.title,
    required this.verificationStatus,
    this.publisher,
    this.sourceUrl,
    this.publicationYear,
  });

  final String title;
  final String? publisher;
  final String? sourceUrl;
  final int? publicationYear;
  final String verificationStatus;

  factory FtrSource.fromMap(Map<String, dynamic> map) => FtrSource(
        title: (map['title'] as String?) ?? '',
        publisher: map['publisher'] as String?,
        sourceUrl: map['source_url'] as String?,
        publicationYear: map['publication_year'] as int?,
        verificationStatus:
            (map['verification_status'] as String?) ?? 'pending',
      );
}
