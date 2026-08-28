#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
LEGAL = ROOT / "supabase/functions/legal-pages/index.ts"

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

# FTR is an education app and currently requires network access only. If one of
# these permissions is ever intentionally introduced, the Play declaration,
# privacy policy and in-app disclosure flow must be redesigned first rather
# than silently expanding the data surface in a routine build.
BLOCKED_PERMISSIONS = {
    "android.permission.BODY_SENSORS",
    "android.permission.BODY_SENSORS_BACKGROUND",
    "android.permission.ACTIVITY_RECOGNITION",
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.READ_CONTACTS",
    "android.permission.READ_CALENDAR",
    "android.permission.READ_SMS",
    "android.permission.READ_PHONE_STATE",
    "android.permission.health.READ_HEART_RATE",
    "android.permission.health.READ_OXYGEN_SATURATION",
    "android.permission.health.READ_SKIN_TEMPERATURE",
    "android.permission.health.READ_EXERCISE",
    "android.permission.health.READ_STEPS",
    "android.permission.health.READ_SLEEP",
}


def fail(errors: list[str], details: dict) -> int:
    print(json.dumps({"ok": False, "errors": errors, **details}, ensure_ascii=False, indent=2))
    return 2


def main() -> int:
    errors: list[str] = []
    details: dict = {}

    if not MANIFEST.exists():
        errors.append("android_manifest_missing")
        permissions: list[str] = []
    else:
        try:
            root = ET.parse(MANIFEST).getroot()
            permissions = sorted(
                {
                    node.attrib.get(f"{ANDROID_NS}name", "").strip()
                    for node in root.findall("uses-permission")
                    if node.attrib.get(f"{ANDROID_NS}name", "").strip()
                }
            )
        except ET.ParseError:
            permissions = []
            errors.append("android_manifest_invalid_xml")

    details["declared_permissions"] = permissions
    blocked_found = sorted(set(permissions) & BLOCKED_PERMISSIONS)
    details["blocked_permissions_found"] = blocked_found
    if blocked_found:
        errors.append("unexpected_sensitive_android_permission")

    # Current product design intentionally asks for network access only. This
    # stronger invariant catches accidental manifest growth even for a
    # permission that was not anticipated in BLOCKED_PERMISSIONS above.
    unexpected_permissions = sorted(set(permissions) - {"android.permission.INTERNET"})
    details["unexpected_permissions"] = unexpected_permissions
    if unexpected_permissions:
        errors.append("android_permission_surface_changed")

    if not LEGAL.exists():
        errors.append("legal_pages_source_missing")
        legal = ""
    else:
        legal = LEGAL.read_text(encoding="utf-8")

    legal_lower = legal.lower()
    legal_checks = {
        "privacy_policy_named": "gizlilik politikası" in legal_lower,
        "app_identity_present": "ftr – fizik tedavi ve rehabilitasyon" in legal_lower
        or "ftr - fizik tedavi ve rehabilitasyon" in legal_lower,
        "privacy_contact_mechanism": "doğrulanmış geliştirici iletişim kanalını" in legal_lower,
        "external_account_deletion_link": "/functions/v1/account-deletion" in legal,
        "data_categories_disclosed": "işlenen veriler" in legal_lower,
        "service_providers_disclosed": "supabase" in legal_lower and "google play" in legal_lower,
        "security_disclosed": "satır düzeyi güvenlik" in legal_lower and "https" in legal_lower,
        "retention_deletion_disclosed": "saklama ve silme" in legal_lower and "hesapla birlikte silinir" in legal_lower,
        "health_data_scope_disclosed": "health connect" in legal_lower and "hasta kayıt sistemi değildir" in legal_lower,
        "medical_device_disclaimer": "tıbbi cihaz değildir" in legal_lower,
        "diagnosis_treatment_disclaimer": all(
            token in legal_lower for token in ("teşhis", "tedavi", "iyileştirme", "önleme")
        ),
    }
    details["legal_checks"] = legal_checks
    errors.extend(name for name, ok in legal_checks.items() if not ok)

    result = {"ok": not errors, "errors": errors, **details}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
