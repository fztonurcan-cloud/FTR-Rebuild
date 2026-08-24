import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/config/app_config.dart';

enum BillingFlowStage {
  pending,
  verifying,
  verified,
  failed,
  canceled,
}

class BillingFlowEvent {
  const BillingFlowEvent(this.stage, this.message);
  final BillingFlowStage stage;
  final String message;
}

class PurchaseService {
  PurchaseService({InAppPurchase? store}) : _store = store ?? InAppPurchase.instance;

  Set<String> get productIds => AppConfig.configuredPlayProductIds;

  final InAppPurchase _store;
  final StreamController<BillingFlowEvent> _flowController =
      StreamController<BillingFlowEvent>.broadcast();

  Stream<List<PurchaseDetails>> get purchaseUpdates => _store.purchaseStream;
  Stream<BillingFlowEvent> get flowEvents => _flowController.stream;

  void publishFlow(BillingFlowStage stage, String message) {
    if (!_flowController.isClosed) {
      _flowController.add(BillingFlowEvent(stage, message));
    }
  }

  Future<ProductDetailsResponse> loadProducts() async {
    if (productIds.isEmpty) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: const [],
        error: IAPError(
          source: 'configuration',
          code: 'product_ids_not_configured',
          message: 'Google Play ürün kimlikleri henüz release yapılandırmasına eklenmedi.',
        ),
      );
    }

    final available = await _store.isAvailable();
    if (!available) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: productIds.toList(growable: false),
        error: IAPError(
          source: 'store',
          code: 'unavailable',
          message: 'Store kullanılamıyor',
        ),
      );
    }
    return _store.queryProductDetails(productIds);
  }

  Future<bool> startSubscription(
    ProductDetails product, {
    String? applicationUserName,
  }) {
    final param = PurchaseParam(
      productDetails: product,
      applicationUserName: applicationUserName,
    );
    return _store.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() => _store.restorePurchases();

  Future<void> complete(PurchaseDetails purchase) =>
      _store.completePurchase(purchase);

  Future<void> dispose() => _flowController.close();
}

// Production rule: purchaseStream sonucu tek başına Premium erişim vermez.
// Purchase token trusted backend'e gönderilir; entitlement yalnızca
// gerçek mağaza sunucu doğrulaması başarılıysa aktif edilir.
