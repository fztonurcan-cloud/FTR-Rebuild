class FtrAsset {
  const FtrAsset({
    required this.id,
    required this.assetType,
    required this.accessScope,
    required this.storagePath,
    required this.sortOrder,
    this.caption,
    this.altText,
    this.placementAfterHeading,
  });

  final String id;
  final String assetType;
  final String accessScope;
  final String storagePath;
  final int sortOrder;
  final String? caption;
  final String? altText;
  final String? placementAfterHeading;

  bool get isImage => assetType == 'image';

  factory FtrAsset.fromMap(Map<String, dynamic> map) {
    return FtrAsset(
      id: map['id'].toString(),
      assetType: (map['asset_type'] as String?) ?? 'file',
      accessScope: (map['access_scope'] as String?) ?? 'protected',
      storagePath: (map['storage_path'] as String?) ?? '',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      caption: map['caption'] as String?,
      altText: map['alt_text'] as String?,
      placementAfterHeading: map['placement_after_heading'] as String?,
    );
  }
}
