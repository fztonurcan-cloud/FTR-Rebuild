import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingVerificationException implements Exception {
  const BillingVerificationException(this.code, [this.details]);

  final String code;
  final Object? details;

  @override
  String toString() => 'BillingVerificationException($code)';
}


class BillingReadiness {
  const BillingReadiness({
    required this.androidVerificationConfigured,
    required this.rtdnConfigured,
    required this.allowedProductCount,
  });

  const BillingReadiness.notConfigured()
      : androidVerificationConfigured = false,
        rtdnConfigured = false,
        allowedProductCount = 0;

  final bool androidVerificationConfigured;
  final bool rtdnConfigured;
  final int allowedProductCount;

  factory BillingReadiness.fromMap(Map<String, dynamic> map) {
    return BillingReadiness(
      androidVerificationConfigured:
          map['androidVerificationConfigured'] == true,
      rtdnConfigured: map['rtdnConfigured'] == true,
      allowedProductCount:
          (map['allowedProductCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.isPremium,
    this.status,
    this.productId,
    this.expiresAt,
    this.platform,
  });

  const PremiumEntitlement.none()
      : isPremium = false,
        status = null,
        productId = null,
        expiresAt = null,
        platform = null;

  final bool isPremium;
  final String? status;
  final String? productId;
  final DateTime? expiresAt;
  final String? platform;

  factory PremiumEntitlement.fromMap(Map<String, dynamic> map) {
    final rawExpiry = map['expires_at'];
    return PremiumEntitlement(
      isPremium: map['is_premium'] == true,
      status: map['status'] as String?,
      productId: map['product_id'] as String?,
      expiresAt: rawExpiry is String ? DateTime.tryParse(rawExpiry) : null,
      platform: map['platform'] as String?,
    );
  }
}

class BillingBackendService {
  const BillingBackendService(this._client);

  final SupabaseClient _client;


  Future<BillingReadiness> fetchReadiness() async {
    try {
      final response = await _client.functions.invoke('billing-readiness');
      final data = response.data;
      if (data is Map) {
        return BillingReadiness.fromMap(Map<String, dynamic>.from(data));
      }
      return const BillingReadiness.notConfigured();
    } catch (_) {
      return const BillingReadiness.notConfigured();
    }
  }

  Future<PremiumEntitlement> fetchEntitlement() async {
    if (_client.auth.currentUser == null) {
      return const PremiumEntitlement.none();
    }

    final result = await _client.rpc('get_my_entitlement');
    if (result is List && result.isNotEmpty && result.first is Map) {
      return PremiumEntitlement.fromMap(
        Map<String, dynamic>.from(result.first as Map),
      );
    }
    if (result is Map) {
      return PremiumEntitlement.fromMap(Map<String, dynamic>.from(result));
    }
    return const PremiumEntitlement.none();
  }

  Future<PremiumEntitlement> verifyStorePurchase(PurchaseDetails purchase) async {
    if (!Platform.isAndroid) {
      throw const BillingVerificationException('app_store_not_configured');
    }

    final session = _client.auth.currentSession;
    if (session == null) {
      throw const BillingVerificationException('auth_required');
    }

    final purchaseToken =
        purchase.verificationData.serverVerificationData.trim();
    if (purchaseToken.length < 8) {
      throw const BillingVerificationException('invalid_purchase_token');
    }

    try {
      final response = await _client.functions.invoke(
        'verify-google-subscription',
        body: {'purchaseToken': purchaseToken},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      final data = response.data;
      if (data is! Map || data['verified'] != true) {
        final code = data is Map ? data['error']?.toString() : null;
        throw BillingVerificationException(
          code ?? 'purchase_not_verified',
          data,
        );
      }
    } on FunctionsHttpException catch (error) {
      final details = error.details;
      String code = 'billing_http_${error.status}';
      if (details is Map && details['error'] != null) {
        code = details['error'].toString();
      }
      throw BillingVerificationException(code, details);
    } on FunctionsFetchException catch (error) {
      throw BillingVerificationException('billing_network_error', error.details);
    }

    return fetchEntitlement();
  }
}
