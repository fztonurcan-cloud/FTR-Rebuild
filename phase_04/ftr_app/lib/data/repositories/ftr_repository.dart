import '../../domain/models/ftr_category.dart';
import '../../domain/models/ftr_content.dart';

abstract interface class FtrRepository {
  Future<List<FtrCategory>> fetchCategories();
  Future<List<FtrContent>> fetchFeaturedContents();
  Future<List<FtrContent>> fetchContentsByCategory(String categoryName);
  Future<List<FtrContent>> search(String query);
  Future<FtrContent?> fetchContentDetail(String id);
}
