import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers.dart';
import '../../../services/billing_backend_service.dart';
import '../../../services/purchase_service.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  ProductDetailsResponse? products;
  bool loading = true;
  bool processingPurchase = false;
  String? selectedProductId;
  String? purchaseMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await ref.read(purchaseServiceProvider).loadProducts();
    if (!mounted) return;
    setState(() {
      products = response;
      loading = false;
      if (response.productDetails.isNotEmpty) {
        selectedProductId ??= response.productDetails.first.id;
      }
    });
  }

  Future<void> _purchase(ProductDetails product) async {
    final readiness = ref.read(billingReadinessProvider).value;
    if (!_isBackendReady(readiness)) {
      if (mounted) {
        setState(() {
          purchaseMessage =
              'Satın alma henüz etkin değil. Sunucu doğrulaması tamamlanmadan ücretlendirme başlatılmayacak.';
        });
      }
      return;
    }

    final user = ref.read(authUserProvider).value;
    if (user == null) {
      await context.push('/auth');
      return;
    }

    setState(() {
      processingPurchase = true;
      purchaseMessage = 'Google Play açılıyor…';
    });

    try {
      final started = await ref.read(purchaseServiceProvider).startSubscription(
            product,
            applicationUserName: user.id,
          );
      if (!started && mounted) {
        setState(() {
          processingPurchase = false;
          purchaseMessage = 'Satın alma ekranı başlatılamadı.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        processingPurchase = false;
        purchaseMessage = 'Google Play satın alma akışı başlatılamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _restore() async {
    final readiness = ref.read(billingReadinessProvider).value;
    if (!_isBackendReady(readiness)) {
      if (mounted) {
        setState(() {
          purchaseMessage =
              'Satın alma doğrulama altyapısı hazır olduğunda geri yükleme kullanılabilecek.';
        });
      }
      return;
    }

    final user = ref.read(authUserProvider).value;
    if (user == null) {
      await context.push('/auth');
      return;
    }
    setState(() {
      processingPurchase = true;
      purchaseMessage = 'Satın almalar kontrol ediliyor…';
    });
    try {
      await ref.read(purchaseServiceProvider).restorePurchases();
      if (!mounted) return;
      if (purchaseMessage == 'Satın almalar kontrol ediliyor…') {
        setState(() {
          processingPurchase = false;
          purchaseMessage = 'Geri yükleme isteği tamamlandı. Uygun bir satın alma bulunursa sunucuda doğrulanacak.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        processingPurchase = false;
        purchaseMessage = 'Satın almalar geri yüklenemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  bool _isBackendReady(BillingReadiness? readiness) {
    return readiness?.androidVerificationConfigured == true &&
        readiness?.rtdnConfigured == true &&
        (readiness?.allowedProductCount ?? 0) > 0 &&
        AppConfig.hasPlayProductConfiguration;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<BillingFlowEvent>>(
      billingFlowEventsProvider,
      (previous, next) {
        final event = next.value;
        if (event == null || !mounted) return;
        setState(() {
          processingPurchase = event.stage == BillingFlowStage.pending ||
              event.stage == BillingFlowStage.verifying;
          purchaseMessage = event.message;
        });
      },
    );
    ref.listen<AsyncValue<PremiumEntitlement>>(
      premiumEntitlementProvider,
      (previous, next) {
        final entitlement = next.value;
        if (entitlement?.isPremium == true && mounted) {
          setState(() {
            processingPurchase = false;
            purchaseMessage = 'Premium erişimin aktif edildi.';
          });
        }
      },
    );

    final items = products?.productDetails ?? const <ProductDetails>[];
    final selected = items.where((item) => item.id == selectedProductId).firstOrNull;
    final readinessAsync = ref.watch(billingReadinessProvider);
    final readiness = readinessAsync.value ?? const BillingReadiness.notConfigured();
    final billingReady = _isBackendReady(readiness) && items.isNotEmpty;
    final entitlementAsync = ref.watch(premiumEntitlementProvider);
    final entitlement = entitlementAsync.value ?? const PremiumEntitlement.none();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Premium'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 34),
        children: [
          const SizedBox(height: 6),
          const Center(
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 82,
              color: AppColors.premium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entitlement.isPremium ? 'Premium aktif' : 'Tüm içeriklere sınırsız erişim!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (entitlement.isPremium) ...[
            const SizedBox(height: 7),
            Text(
              _entitlementDescription(entitlement),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 22),
          const _Benefit(text: 'Premium ders ve içeriklere erişim'),
          const _Benefit(text: 'Egzersiz kütüphanesi ve yeni içerikler'),
          const _Benefit(text: 'Favoriler, notlar ve ilerleme senkronizasyonu'),
          const _Benefit(text: 'Güvenli hesap ve cihazlar arası devamlılık'),
          const SizedBox(height: 25),
          if (entitlement.isPremium)
            _ActivePlanCard(entitlement: entitlement)
          else if (loading)
            const Center(child: CircularProgressIndicator())
          else if (items.isEmpty)
            const _BillingLockedCard()
          else
            ...items.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanCard(
                  product: product,
                  selected: product.id == selectedProductId,
                  label: _planLabel(product),
                  badge: product.id == AppConfig.playMonthlyProductId ? 'En popüler' : null,
                  onTap: () => setState(() => selectedProductId = product.id),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (!entitlement.isPremium)
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: processingPurchase || !billingReady || selected == null
                    ? null
                    : () => _purchase(selected),
                child: processingPurchase
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Devam Et'),
              ),
            ),
          if (!billingReady && !entitlement.isPremium) ...[
            const SizedBox(height: 12),
            Text(
              readinessAsync.isLoading
                  ? 'Satın alma güvenliği kontrol ediliyor…'
                  : 'Ücretlendirme, gerçek Play ürünleri ve sunucu doğrulaması tamamlanana kadar kapalı tutulur.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (purchaseMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              purchaseMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: processingPurchase || !_isBackendReady(readiness)
                ? null
                : _restore,
            child: const Text('Satın almayı geri yükle'),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium erişim yalnızca Google Play işlemi güvenilir sunucuda doğrulandıktan sonra açılır.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _planLabel(ProductDetails product) {
    if (product.id == AppConfig.playMonthlyProductId) return 'Aylık Premium';
    if (product.id == AppConfig.playYearlyProductId) return 'Yıllık Premium';
    return product.title;
  }

  String _entitlementDescription(PremiumEntitlement entitlement) {
    final expiry = entitlement.expiresAt?.toLocal();
    final expiryText = expiry == null
        ? ''
        : ' • ${expiry.day.toString().padLeft(2, '0')}.${expiry.month.toString().padLeft(2, '0')}.${expiry.year} tarihine kadar';
    return '${entitlement.status ?? 'active'}$expiryText';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.selected,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final ProductDetails product;
  final bool selected;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary600 : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4DC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(color: Color(0xFF9E6A00), fontSize: 9.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(product.price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.primary600 : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      );
}

class _BillingLockedCard extends StatelessWidget {
  const _BillingLockedCard();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_clock_outlined, color: AppColors.primary600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppConfig.hasPlayProductConfiguration
                      ? 'Google Play mağaza ürünleri henüz cihazda alınamadı.'
                      : 'Gerçek Google Play ürün kimlikleri Play Console’dan tanımlanana kadar plan seçimi kapalıdır.',
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.entitlement});
  final PremiumEntitlement entitlement;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Premium aboneliğiniz sunucu tarafından doğrulanmış durumda.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.check_rounded, color: AppColors.primary600, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

extension _FirstOrNullProductDetails on Iterable<ProductDetails> {
  ProductDetails? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
