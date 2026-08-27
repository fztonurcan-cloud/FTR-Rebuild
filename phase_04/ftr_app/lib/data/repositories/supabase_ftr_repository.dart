import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/ftr_category.dart';
import '../../domain/models/ftr_content.dart';
import 'ftr_repository.dart';

class SupabaseFtrRepository implements FtrRepository {
  const SupabaseFtrRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<FtrCategory>> fetchCategories() async {
    final rows = await client.from('category_catalog').select().order('sort_order');
    return (rows as List).cast<Map<String, dynamic>>().map(FtrCategory.fromMap).toList();
  }

  @override
  Future<List<FtrContent>> fetchFeaturedContents() async {
    final rows = await client.from('content_catalog').select().limit(10);
    return (rows as List).cast<Map<String, dynamic>>().map(FtrContent.fromMap).toList();
  }

  @override
  Future<List<FtrContent>> fetchContentsByCategory(
    String categoryName, {
    int offset = 0,
    int limit = 50,
  }) async {
    if (limit <= 0) return const [];
    final safeOffset = offset < 0 ? 0 : offset;
    final rows = await client
        .from('content_catalog')
        .select()
        .eq('category_name', categoryName)
        .order('title')
        .order('id')
        .range(safeOffset, safeOffset + limit - 1);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(FtrContent.fromMap)
        .toList();
  }

  @override
  Future<List<FtrContent>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await client.from('content_catalog').select().ilike('title', '%$q%').limit(30);
    return (rows as List).cast<Map<String, dynamic>>().map(FtrContent.fromMap).toList();
  }

  @override
  Future<FtrContent?> fetchContentDetail(String id) async {
    final rows = await client.rpc('get_content_detail', params: {'p_content_id': id});
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return FtrContent.fromMap(list.first);
  }
}
