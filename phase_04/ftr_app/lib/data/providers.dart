import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/config/app_config.dart';
import '../domain/models/ftr_category.dart';
import '../domain/models/ftr_content.dart';
import '../domain/models/ftr_quiz.dart';
import '../domain/models/user_note.dart';
import 'repositories/ftr_repository.dart';
import 'repositories/mock_ftr_repository.dart';
import 'repositories/supabase_ftr_repository.dart';
import '../services/auth_service.dart';
import '../services/billing_backend_service.dart';
import '../services/purchase_service.dart';
import '../services/quiz_service.dart';
import '../services/user_library_service.dart';

final ftrRepositoryProvider = Provider<FtrRepository>((ref) {
  if (AppConfig.useMockContent || !AppConfig.hasSupabaseConfiguration) {
    return const MockFtrRepository();
  }
  return SupabaseFtrRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider<List<FtrCategory>>((ref) {
  return ref.watch(ftrRepositoryProvider).fetchCategories();
});

final featuredContentsProvider = FutureProvider<List<FtrContent>>((ref) {
  return ref.watch(ftrRepositoryProvider).fetchFeaturedContents();
});

final contentDetailProvider = FutureProvider.family<FtrContent?, String>((ref, id) {
  return ref.watch(ftrRepositoryProvider).fetchContentDetail(id);
});

final authServiceProvider = Provider<AuthService?>((ref) {
  if (!AppConfig.hasSupabaseConfiguration) return null;
  return AuthService(Supabase.instance.client);
});

final authUserProvider = StreamProvider<User?>((ref) async* {
  final service = ref.watch(authServiceProvider);
  if (service == null) {
    yield null;
    return;
  }
  yield* service.userChanges;
});

final quizServiceProvider = Provider<QuizService?>((ref) {
  if (!AppConfig.hasSupabaseConfiguration) return null;
  return QuizService(Supabase.instance.client);
});

final quizQuestionsProvider = FutureProvider.family<List<FtrQuizQuestion>, String>((ref, contentId) async {
  ref.watch(authUserProvider);
  final service = ref.watch(quizServiceProvider);
  if (service == null) throw StateError('Supabase yapılandırması bulunamadı.');
  return service.fetchQuestions(contentId);
});

final userLibraryServiceProvider = Provider<UserLibraryService?>((ref) {
  if (!AppConfig.hasSupabaseConfiguration) return null;
  return UserLibraryService(Supabase.instance.client);
});

final favoritesProvider = FutureProvider<List<FtrContent>>((ref) async {
  ref.watch(authUserProvider);
  final service = ref.watch(userLibraryServiceProvider);
  if (service == null) return const [];
  return service.fetchFavorites();
});

final favoriteStateProvider = FutureProvider.family<bool, String>((ref, contentId) async {
  ref.watch(authUserProvider);
  final service = ref.watch(userLibraryServiceProvider);
  if (service == null) return false;
  return service.isFavorite(contentId);
});

final notesProvider = FutureProvider<List<UserNote>>((ref) async {
  ref.watch(authUserProvider);
  final service = ref.watch(userLibraryServiceProvider);
  if (service == null) return const [];
  return service.fetchNotes();
});

final contentProgressProvider = FutureProvider.family<double, String>((ref, contentId) async {
  ref.watch(authUserProvider);
  final service = ref.watch(userLibraryServiceProvider);
  if (service == null) return 0;
  return service.fetchProgress(contentId);
});

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final billingBackendServiceProvider = Provider<BillingBackendService?>((ref) {
  if (!AppConfig.hasSupabaseConfiguration) return null;
  return BillingBackendService(Supabase.instance.client);
});

final billingReadinessProvider = FutureProvider<BillingReadiness>((ref) async {
  final service = ref.watch(billingBackendServiceProvider);
  if (service == null) return const BillingReadiness.notConfigured();
  return service.fetchReadiness();
});

final premiumEntitlementProvider = FutureProvider<PremiumEntitlement>((ref) async {
  ref.watch(authUserProvider);
  final service = ref.watch(billingBackendServiceProvider);
  if (service == null) return const PremiumEntitlement.none();
  return service.fetchEntitlement();
});

final purchaseUpdatesProvider = StreamProvider<List<PurchaseDetails>>((ref) {
  return ref.watch(purchaseServiceProvider).purchaseUpdates;
});

final billingFlowEventsProvider = StreamProvider<BillingFlowEvent>((ref) {
  return ref.watch(purchaseServiceProvider).flowEvents;
});
