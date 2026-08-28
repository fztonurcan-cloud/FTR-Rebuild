import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/ftr_category.dart';
import '../../domain/models/ftr_content.dart';
import '../../services/internal_preview_service.dart';
import 'ftr_repository.dart';

class SupabaseFtrRepository implements FtrRepository {
  const SupabaseFtrRepository(
    this.client, {
    this.internalReviewPreview = false,
  });

  final SupabaseClient client;
  final bool internalReviewPreview;

  InternalPreviewService get _preview => InternalPreviewService(client);

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
      raw = await _preview.invoke('categories');
    } else {
      raw = await client.from('category_catalog').select().order('sort_order');
    }
    return _rows(raw).map(FtrCategory.fromMap).toList(growable: false);
  }

  @override
  Future<List<FtrContent>> fetchFeaturedContents() async {
    final dynamic raw;
    if (internalReviewPreview) {
      raw = await _preview.invoke('featured', payload: {'limit': 10});
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
      raw = await _preview.invoke(
        'category',
        payload: {
          'category_name': categoryName,
          'offset': safeOffset,
          'limit': limit,
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

    final dynamic raw;
    if (internalReviewPreview) {
      raw = await _preview.invoke('search', payload: {'query': q, 'limit': 30});
    } else {
      raw = await client.rpc(
        'search_published_contents',
        params: {'p_query': q, 'p_limit': 30},
      );
    }
    return _rows(raw).map(FtrContent.fromMap).toList(growable: false);
  }

  @override
  Future<FtrContent?> fetchContentDetail(String id) async {
    if (internalReviewPreview) {
      final raw = await _preview.invoke('detail', payload: {'content_id': id});
      if (raw is! Map) return null;
      return FtrContent.fromMap(Map<String, dynamic>.from(raw));
    }

    final raw = await client.rpc(
      'get_content_detail',
      params: {'p_content_id': id},
    );
    final rows = _rows(raw);
    if (rows.isEmpty) return null;
    return FtrContent.fromMap(rows.first);
  }
}
