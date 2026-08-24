#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shutil
from pathlib import Path

EXPECTED = {
    "flutter_riverpod": "3.4.2",
    "go_router": "17.5.0",
    "supabase_flutter": "2.17.2",
    "in_app_purchase": "3.3.0",
    "flutter_html": "3.0.0",
    "flutter_lints": "6.0.0",
}
FORBIDDEN_PATTERNS = {
    "supabase_secret_key": re.compile(r"\bsb_secret_[A-Za-z0-9_-]{8,}"),
    "legacy_service_role_label": re.compile(r"service[_ -]?role\s*[:=]\s*['\"][A-Za-z0-9._-]{20,}", re.I),
    "jwt_like": re.compile(r"\beyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
}
LEGACY_MEDIA_HOSTS = ("hizliresim.com", "resimyukle.xyz", "fztdulger.com", "documentcloud.adobe.com")
REQUIRED_DART_MIN = "3.13.0"
REQUIRED_FLUTTER_MIN = "3.47.0"


def parse_dep_versions(pubspec: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for name in EXPECTED:
        m = re.search(rf"^\s*{re.escape(name)}:\s*([\^~]?[0-9][^\s#]*)", pubspec, re.M)
        if m:
            out[name] = m.group(1).strip()
    return out


def parse_environment(pubspec: str) -> dict[str, str | None]:
    dart = re.search(r'^\s{2}sdk:\s*["\']([^"\']+)["\']\s*$', pubspec, re.M)
    flutter = re.search(r'^\s{2}flutter:\s*["\']([^"\']+)["\']\s*$', pubspec, re.M)
    return {"dart": dart.group(1) if dart else None, "flutter": flutter.group(1) if flutter else None}


def relative_import_errors(root: Path) -> list[str]:
    errors: list[str] = []
    for file in root.glob("lib/**/*.dart"):
        text = file.read_text(encoding="utf-8")
        for spec in re.findall(r"^\s*import\s+['\"]([^'\"]+)['\"]", text, re.M):
            if spec.startswith(("dart:", "package:")):
                continue
            target = (file.parent / spec).resolve()
            if not target.is_file():
                errors.append(f"{file.relative_to(root)} -> missing {spec}")
    return errors


def scan_text(root: Path) -> tuple[list[str], list[str]]:
    secret_hits: list[str] = []
    legacy_hits: list[str] = []
    candidates = [*root.glob("lib/**/*.dart"), root / "pubspec.yaml"]
    for file in candidates:
        if not file.is_file():
            continue
        text = file.read_text(encoding="utf-8", errors="ignore")
        for name, pattern in FORBIDDEN_PATTERNS.items():
            if pattern.search(text):
                secret_hits.append(f"{file.relative_to(root)}: {name}")
        lower = text.lower()
        for host in LEGACY_MEDIA_HOSTS:
            if host in lower:
                legacy_hits.append(f"{file.relative_to(root)}: {host}")
    return secret_hits, legacy_hits


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="Flutter app root")
    parser.add_argument("--strict", action="store_true", help="Require Flutter/Dart, pubspec.lock and the requested platform on PATH/disk")
    parser.add_argument(
        "--platform",
        choices=("source", "android", "ios", "all"),
        default="source",
        help="Platform gate to enforce in strict mode (default: source only)",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    pubspec_path = root / "pubspec.yaml"
    if not pubspec_path.is_file():
        print(json.dumps({"ok": False, "error": "pubspec.yaml missing"}, indent=2))
        return 2

    pubspec = pubspec_path.read_text(encoding="utf-8")
    versions = parse_dep_versions(pubspec)
    version_mismatches = {
        name: {"expected": expected, "found": versions.get(name)}
        for name, expected in EXPECTED.items()
        if versions.get(name) != expected
    }
    environment = parse_environment(pubspec)
    environment_errors = []
    if environment["dart"] != ">=3.13.0 <4.0.0":
        environment_errors.append(f"Dart constraint must be >=3.13.0 <4.0.0; found {environment['dart']!r}")
    if environment["flutter"] != ">=3.47.0":
        environment_errors.append(f"Flutter constraint must be >=3.47.0; found {environment['flutter']!r}")

    import_errors = relative_import_errors(root)
    secret_hits, legacy_hits = scan_text(root)

    report = {
        "ok_source_static": not import_errors and not secret_hits and not legacy_hits and not version_mismatches and not environment_errors,
        "flutter_on_path": shutil.which("flutter") is not None,
        "dart_on_path": shutil.which("dart") is not None,
        "android_platform_present": (root / "android").is_dir(),
        "ios_platform_present": (root / "ios").is_dir(),
        "pubspec_lock_present": (root / "pubspec.lock").is_file(),
        "requested_platform_gate": args.platform,
        "dependency_versions": versions,
        "dependency_version_mismatches": version_mismatches,
        "environment_constraints": environment,
        "environment_errors": environment_errors,
        "relative_import_errors": import_errors,
        "secret_hits": secret_hits,
        "legacy_media_host_hits_in_client": legacy_hits,
        "required_android_min_sdk": 24,
        "required_android_compile_sdk": 36,
        "required_android_target_sdk": 36,
        "required_ios_deployment_target": "13.0",
        "required_flutter_baseline": REQUIRED_FLUTTER_MIN,
        "required_dart_baseline": REQUIRED_DART_MIN,
        "package_identity_gate": "Android bootstrap requires FTR_PACKAGE_IDENTITY_CONFIRMED=YES plus the confirmed Android applicationId; iOS identity is gated separately.",
        "release_version_gate": "Existing Play listing updates must use a versionCode greater than the highest versionCode already in Play Console.",
    }

    print(json.dumps(report, ensure_ascii=False, indent=2))

    hard_errors = bool(import_errors or secret_hits or legacy_hits or version_mismatches or environment_errors)
    platform_ready = {
        "source": True,
        "android": report["android_platform_present"],
        "ios": report["ios_platform_present"],
        "all": report["android_platform_present"] and report["ios_platform_present"],
    }[args.platform]
    build_blocked = not (
        report["flutter_on_path"]
        and report["dart_on_path"]
        and report["pubspec_lock_present"]
        and platform_ready
    )
    if hard_errors:
        return 1
    if args.strict and build_blocked:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
