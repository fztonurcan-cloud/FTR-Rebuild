import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../data/providers.dart';
import '../services/billing_backend_service.dart';
import '../services/purchase_service.dart';
import 'router.dart';

class FtrApp extends ConsumerStatefulWidget {
  const FtrApp({super.key});

  @override
  ConsumerState<FtrApp> createState() => _FtrAppState();
}

class _FtrAppState extends ConsumerState<FtrApp> {
  StreamSubscription<AuthState>? _authSubscription;
  Future<void> _purchaseQueue = Future<void>.value();
  final Set<String> _handledPurchaseKeys = <String>{};


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authServiceProvider);
      _authSubscription = auth?.authStates.listen((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          appRouter.go('/reset-password');
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<PurchaseDetails>>>(
      purchaseUpdatesProvider,
      (previous, next) {
        next.whenData(_enqueuePurchases);
      },
    );

    return MaterialApp.router(
      title: 'FTR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }

  void _enqueuePurchases(List<PurchaseDetails> purchases) {
    _purchaseQueue = _purchaseQueue
        .then((_) => _processPurchases(purchases))
        .catchError((Object _, StackTrace __) {
      ref.read(purchaseServiceProvider).publishFlow(
            BillingFlowStage.failed,
            'Satın alma akışı işlenemedi. Premium erişim değiştirilmedi.',
          );
    });
  }

  Future<void> _processPurchases(List<PurchaseDetails> purchases) async {
    final backend = ref.read(billingBackendServiceProvider);
    final purchaseService = ref.read(purchaseServiceProvider);
    if (backend == null) return;

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchaseService.publishFlow(
            BillingFlowStage.pending,
            'Ödeme Google Play tarafından işleniyor…',
          );
          break;

        case PurchaseStatus.error:
          purchaseService.publishFlow(
            BillingFlowStage.failed,
            purchase.error?.message ?? 'Satın alma sırasında hata oluştu.',
          );
          break;

        case PurchaseStatus.canceled:
          purchaseService.publishFlow(
            BillingFlowStage.canceled,
            'Satın alma iptal edildi.',
          );
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final purchaseKey = _purchaseKey(purchase);
          if (_handledPurchaseKeys.contains(purchaseKey)) {
            continue;
          }

          purchaseService.publishFlow(
            BillingFlowStage.verifying,
            'Satın alma sunucuda doğrulanıyor…',
          );
          try {
            final entitlement = await backend.verifyStorePurchase(purchase);
            if (!entitlement.isPremium) {
              purchaseService.publishFlow(
                BillingFlowStage.failed,
                'Doğrulama tamamlandı ancak Premium hak oluşmadı.',
              );
              continue;
            }

            if (purchase.pendingCompletePurchase) {
              try {
                await purchaseService.complete(purchase);
              } catch (_) {
                ref.invalidate(premiumEntitlementProvider);
                purchaseService.publishFlow(
                  BillingFlowStage.failed,
                  'Premium doğrulandı ancak Google Play işlemi tamamlanamadı. Uygulamayı yeniden açıp tekrar kontrol edin.',
                );
                continue;
              }
            }

            _handledPurchaseKeys.add(purchaseKey);
            ref.invalidate(premiumEntitlementProvider);
            purchaseService.publishFlow(
              BillingFlowStage.verified,
              'Premium erişimin aktif edildi.',
            );
          } on BillingVerificationException catch (error) {
            purchaseService.publishFlow(
              BillingFlowStage.failed,
              _billingErrorMessage(error.code),
            );
          } catch (_) {
            purchaseService.publishFlow(
              BillingFlowStage.failed,
              'Satın alma doğrulanamadı. Premium erişim verilmedi.',
            );
          }
          break;
      }
    }
  }

  String _purchaseKey(PurchaseDetails purchase) {
    final purchaseId = purchase.purchaseID?.trim();
    if (purchaseId != null && purchaseId.isNotEmpty) return purchaseId;
    final token = purchase.verificationData.serverVerificationData.trim();
    if (token.isNotEmpty) return token;
    return '${purchase.productID}:${purchase.transactionDate ?? 'unknown'}';
  }

  String _billingErrorMessage(String code) {
    switch (code) {
      case 'billing_not_configured':
        return 'Google Play sunucu doğrulaması henüz yapılandırılmadı.';
      case 'auth_required':
        return 'Satın almayı doğrulamak için hesabınıza giriş yapın.';
      case 'app_store_not_configured':
        return 'App Store sunucu doğrulaması henüz yapılandırılmadı.';
      case 'billing_network_error':
        return 'Doğrulama sunucusuna ulaşılamadı. İşlem tamamlanmadı.';
      case 'invalid_purchase_token':
        return 'Mağazadan geçerli satın alma bilgisi alınamadı.';
      case 'product_not_entitled':
        return 'Bu mağaza ürünü FTR Premium erişimi için tanımlı değil.';
      case 'purchase_account_mismatch':
        return 'Bu satın alma farklı bir kullanıcı hesabıyla eşleşiyor.';
      default:
        return 'Satın alma sunucuda doğrulanamadı. Premium erişim verilmedi.';
    }
  }
}
