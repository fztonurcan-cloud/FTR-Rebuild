#!/usr/bin/env python3
from pathlib import Path
import json
import sys

root = Path(__file__).resolve().parents[1]
app = (root / 'lib/app/app.dart').read_text()
premium = (root / 'lib/features/premium/presentation/premium_screen.dart').read_text()
auth_migration = (root / 'supabase_011_phase45_auth_profile_trigger.sql').read_text()

checks = {
    'purchase_processing_serialized': 'Future<void> _purchaseQueue' in app and '.then((_) => _processPurchases(purchases))' in app,
    'successful_purchase_deduped': '_handledPurchaseKeys' in app and '_handledPurchaseKeys.add(purchaseKey)' in app,
    'complete_purchase_failure_isolated': 'Premium doğrulandı ancak Google Play işlemi tamamlanamadı' in app,
    'billing_requires_rtdn': 'readiness?.rtdnConfigured == true' in premium,
    'billing_requires_allowlist': '(readiness?.allowedProductCount ?? 0) > 0' in premium,
    'billing_requires_product_config': 'AppConfig.hasPlayProductConfiguration' in premium,
    'purchase_start_exception_resets_ui': 'Google Play satın alma akışı başlatılamadı' in premium,
    'empty_restore_resets_ui': 'Geri yükleme isteği tamamlandı.' in premium,
    'restore_exception_resets_ui': 'Satın almalar geri yüklenemedi.' in premium,
    'auth_profile_trigger_mirrored': 'create trigger on_auth_user_created' in auth_migration and 'private.handle_new_user()' in auth_migration,
}
result = {'ok': all(checks.values()), 'checks': checks}
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(0 if result['ok'] else 2)
