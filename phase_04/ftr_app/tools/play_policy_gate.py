#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import unicodedata
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
LEGAL = ROOT / "supabase/functions/legal-pages/index.ts"

ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

# FTR Akademi is an education app and currently requires network access only.
# If one of these permissions is intentionally introduced later, the Play
# declaration, privacy policy and in-app disclosure flow must be redesigned
# first rather than silently expanding the data surface in a routine build.
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


def normalized(text: str) -> str:
    """Case-fold text and remove combining marks so Turkish İ matches i."""
    decomposed = unicodedata.normalize("NFKD", text.casefold())
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def contains_any(haystack: str, *phrases: str) -> bool:
    return any(normalized(phrase) in haystack for phrase in phrases)


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

    legal_norm = normalized(legal)

    # These checks intentionally validate disclosure meaning rather than one
    # frozen sentence. Copy can be improved without weakening the release gate,
    # while removal of the required disclosure still fails the build.
    app_identity_present = contains_any(
        legal_norm,
        "FTR Akademi – Fizik Tedavi ve Rehabilitasyon",
        "FTR Akademi - Fizik Tedavi ve Rehabilitasyon",
        "FTR – Fizik Tedavi ve Rehabilitasyon",
        "FTR - Fizik Tedavi ve Rehabilitasyon",
    )
    privacy_contact_mechanism = (
        "fiziktedaviverehabilitasyon00@gmail.com" in legal.casefold()
        and "mailto:${SUPPORT}" in legal
    ) or contains_any(legal_norm, "doğrulanmış geliştirici iletişim kanalını")
    data_categories_disclosed = contains_any(
        legal_norm,
        "İşlenen veri kategorileri",
        "İşlenen veriler",
    )
    security_disclosed = (
        "https" in legal_norm
        and (
            "rls" in legal_norm
            or contains_any(legal_norm, "satır düzeyi güvenlik")
        )
    )
    retention_deletion_disclosed = (
        contains_any(
            legal_norm,
            "Veri saklama ve silme politikası",
            "Saklama ve silme",
        )
        and contains_any(
            legal_norm,
            "Hesap kalıcı olarak silindiğinde",
            "hesapla birlikte silinir",
        )
        and contains_any(
            legal_norm,
            "uygulama verileri silinir",
            "hesaba bağlı veriler silinir",
            "hesapla birlikte silinir",
        )
    )

    legal_checks = {
        "privacy_policy_named": contains_any(legal_norm, "Gizlilik Politikası"),
        "app_identity_present": app_identity_present,
        "privacy_contact_mechanism": privacy_contact_mechanism,
        "external_account_deletion_link": "/functions/v1/account-deletion" in legal,
        "data_categories_disclosed": data_categories_disclosed,
        "service_providers_disclosed": "supabase" in legal_norm and "google play" in legal_norm,
        "security_disclosed": security_disclosed,
        "retention_deletion_disclosed": retention_deletion_disclosed,
        "health_data_scope_disclosed": "health connect" in legal_norm
        and contains_any(legal_norm, "hasta kayıt sistemi değildir"),
        "medical_device_disclaimer": contains_any(legal_norm, "tıbbi cihaz değildir"),
        "diagnosis_treatment_disclaimer": all(
            normalized(token) in legal_norm for token in ("teşhis", "tedavi", "iyileştirme", "önleme")
        ),
    }
    details["legal_checks"] = legal_checks
    errors.extend(name for name, ok in legal_checks.items() if not ok)

    result = {"ok": not errors, "errors": errors, **details}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 2


if __name__ == "__main__":
    sys.exit(main())
