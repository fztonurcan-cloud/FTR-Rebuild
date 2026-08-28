import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/ftr_category.dart';
import '../../domain/models/ftr_content.dart';
import 'ftr_repository.dart';

class SupabaseFtrRepository implements FtrRepository {
  const SupabaseFtrRepository(
    this.client, {
    this.internalReviewPreview = false,
  });

  final SupabaseClient client;
  final bool internalReviewPreview;

  List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Future<List<FtrCategory>> fetchCategories() async {
    final dynamic raw;
    if (internalReviewPreview) {
      raw = await client.rpc('internal_preview_categories');
    } else {
      raw = await client.from('category_catalog').select().order('sort_order');
    }
    return _rows(raw).map(FtrCategory.fromMap).toList(growable: false);
  }

  @override
  Future<List<FtrContent>> fetchFeaturedContents() async {
    final dynamic raw;
    if (internalReviewPreview) {
      raw = await client.rpc(
        'internal_preview_featured_contents',
        params: {'p_limit': 10},
      );
    } else {
      raw = await client.from('content_catalog').select().limit(10);
    }
    return _rows(raw).map(FtrContent.fromMap).toList(growable: false);
  }

  @override
  Future<List<FtrContent>> fetchContentsByCategory(
    String categoryName, {
    int offset = 0,
    int limit = 50,
  }) async {
    if (limit <= 0) return const [];
    final safeOffset = offset < 0 ? 0 : offset;

    final dynamic raw;
    if (internalReviewPreview) {
      raw = await client.rpc(
        'internal_preview_category_contents',
        params: {
          'p_category_name': categoryName,
          'p_offset': safeOffset,
          'p_limit': limit,
        },
      );
    } else {
      raw = await client
          .from('content_catalog')
          .select()
          .eq('category_name', categoryName)
          .order('title')
          .order('id')
          .range(safeOffset, safeOffset + limit - 1);
    }

    return _rows(raw).map(FtrContent.fromMap).toList(growable: false);
  }

  @override
  Future<List<FtrContent>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final raw = await client.rpc(
      internalReviewPreview
          ? 'internal_preview_search_contents'
          : 'search_published_contents',
      params: {'p_query': q, 'p_limit': 30},
    );
    return _rows(raw).map(FtrContent.fromMap).toList(growable: false);
  }

  @override
  Future<FtrContent?> fetchContentDetail(String id) async {
    final raw = await client.rpc(
      internalReviewPreview
          ? 'internal_preview_content_detail'
          : 'get_content_detail',
      params: {'p_content_id': id},
    );
    final rows = _rows(raw);
    if (rows.isEmpty) return null;
    return FtrContent.fromMap(rows.first);
  }
}
