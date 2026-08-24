#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

ANDROID_ID_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+$")
IOS_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.-]+$")


def validate_ids(android_id: str, ios_id: str) -> None:
    if not ANDROID_ID_RE.fullmatch(android_id):
        raise SystemExit(f"Invalid Android applicationId: {android_id!r}")
    if not IOS_ID_RE.fullmatch(ios_id) or "." not in ios_id:
        raise SystemExit(f"Invalid iOS bundle identifier: {ios_id!r}")


def patch_android_main_activity(root: Path, app_id: str) -> None:
    src_root = root / "android/app/src/main"
    candidates = list((src_root / "kotlin").rglob("MainActivity.kt")) + list((src_root / "java").rglob("MainActivity.java"))
    if len(candidates) != 1:
        raise SystemExit(f"Expected exactly one Android MainActivity source; found {len(candidates)}")
    source = candidates[0]
    text = source.read_text(encoding="utf-8")
    if source.suffix == ".kt":
        text, changed = re.subn(r"^package\s+[A-Za-z0-9_.]+\s*$", f"package {app_id}", text, count=1, flags=re.M)
        lang_root = src_root / "kotlin"
    else:
        text, changed = re.subn(r"^package\s+[A-Za-z0-9_.]+\s*;", f"package {app_id};", text, count=1, flags=re.M)
        lang_root = src_root / "java"
    if changed != 1:
        raise SystemExit("Could not safely patch MainActivity package declaration")
    target = lang_root.joinpath(*app_id.split("."), source.name)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
    if target.resolve() != source.resolve():
        source.unlink()
        # Remove now-empty package folders without touching the language root.
        parent = source.parent
        while parent != lang_root and parent.exists():
            try:
                parent.rmdir()
            except OSError:
                break
            parent = parent.parent


def patch_android(root: Path, app_id: str, min_sdk: int, compile_sdk: int, target_sdk: int) -> None:
    candidates = [
        root / "android/app/build.gradle.kts",
        root / "android/app/build.gradle",
    ]
    build_file = next((p for p in candidates if p.is_file()), None)
    if build_file is None:
        raise SystemExit("Android app Gradle file not found after flutter create")

    text = build_file.read_text(encoding="utf-8")
    if build_file.suffix == ".kts":
        text, n0 = re.subn(r"compileSdk\s*=\s*[^\n]+", f"compileSdk = {compile_sdk}", text, count=1)
        text, n1 = re.subn(r'namespace\s*=\s*"[^"]+"', f'namespace = "{app_id}"', text, count=1)
        text, n2 = re.subn(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{app_id}"', text, count=1)
        text, n3 = re.subn(r"minSdk\s*=\s*[^\n]+", f"minSdk = {min_sdk}", text, count=1)
        text, n4 = re.subn(r"targetSdk\s*=\s*[^\n]+", f"targetSdk = {target_sdk}", text, count=1)
    else:
        text, n0 = re.subn(r"compileSdkVersion\s+[^\n]+", f"compileSdkVersion {compile_sdk}", text, count=1)
        text, n1 = re.subn(r'namespace\s+["\'][^"\']+["\']', f'namespace "{app_id}"', text, count=1)
        text, n2 = re.subn(r'applicationId\s+["\'][^"\']+["\']', f'applicationId "{app_id}"', text, count=1)
        text, n3 = re.subn(r"minSdkVersion\s+[^\n]+", f"minSdkVersion {min_sdk}", text, count=1)
        text, n4 = re.subn(r"targetSdkVersion\s+[^\n]+", f"targetSdkVersion {target_sdk}", text, count=1)
    if not all((n0, n1, n2, n3, n4)):
        raise SystemExit(
            "Could not safely patch Android Gradle file: "
            f"compileSdk={n0}, namespace={n1}, appId={n2}, minSdk={n3}, targetSdk={n4}"
        )
    build_file.write_text(text, encoding="utf-8")

    manifest = root / "android/app/src/main/AndroidManifest.xml"
    if not manifest.is_file():
        raise SystemExit("AndroidManifest.xml not found after flutter create")
    mtext = manifest.read_text(encoding="utf-8")
    if "android.permission.INTERNET" not in mtext:
        open_end = mtext.find(">")
        if open_end < 0:
            raise SystemExit("Malformed AndroidManifest.xml")
        mtext = mtext[: open_end + 1] + '\n    <uses-permission android:name="android.permission.INTERNET" />' + mtext[open_end + 1 :]
        manifest.write_text(mtext, encoding="utf-8")

    patch_android_main_activity(root, app_id)


def patch_ios(root: Path, bundle_id: str, deployment_target: str) -> None:
    pbx = root / "ios/Runner.xcodeproj/project.pbxproj"
    if not pbx.is_file():
        raise SystemExit("iOS project.pbxproj not found after flutter create")
    text = pbx.read_text(encoding="utf-8")
    lines = []
    bundle_changes = 0
    deployment_changes = 0
    for line in text.splitlines():
        if "PRODUCT_BUNDLE_IDENTIFIER =" in line:
            prefix = line.split("PRODUCT_BUNDLE_IDENTIFIER =", 1)[0]
            old = line.split("PRODUCT_BUNDLE_IDENTIFIER =", 1)[1].split(";", 1)[0].strip()
            suffix = ".RunnerTests" if "RunnerTests" in old else ""
            line = f"{prefix}PRODUCT_BUNDLE_IDENTIFIER = {bundle_id}{suffix};"
            bundle_changes += 1
        if "IPHONEOS_DEPLOYMENT_TARGET =" in line:
            prefix = line.split("IPHONEOS_DEPLOYMENT_TARGET =", 1)[0]
            line = f"{prefix}IPHONEOS_DEPLOYMENT_TARGET = {deployment_target};"
            deployment_changes += 1
        lines.append(line)
    if bundle_changes == 0:
        raise SystemExit("Could not find iOS PRODUCT_BUNDLE_IDENTIFIER")
    if deployment_changes == 0:
        raise SystemExit("Could not find iOS IPHONEOS_DEPLOYMENT_TARGET")
    pbx.write_text("\n".join(lines) + "\n", encoding="utf-8")

    podfile = root / "ios/Podfile"
    if podfile.is_file():
        ptext = podfile.read_text(encoding="utf-8")
        if re.search(r"^platform :ios,", ptext, flags=re.M):
            ptext = re.sub(r"^platform :ios,\s*['\"][^'\"]+['\"]", f"platform :ios, '{deployment_target}'", ptext, count=1, flags=re.M)
        else:
            ptext = f"platform :ios, '{deployment_target}'\n\n" + ptext
        podfile.write_text(ptext, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--android-id", required=True)
    parser.add_argument("--ios-id", required=True)
    parser.add_argument("--min-sdk", type=int, default=24)
    parser.add_argument("--compile-sdk", type=int, default=36)
    parser.add_argument("--target-sdk", type=int, default=36)
    parser.add_argument("--ios-deployment-target", default="13.0")
    args = parser.parse_args()

    validate_ids(args.android_id, args.ios_id)
    if args.min_sdk < 24:
        raise SystemExit("minSdk must be >=24 because in_app_purchase 3.3.0 supports Android SDK 24+")
    if args.compile_sdk < 36:
        raise SystemExit("compileSdk must be >=36 for the Phase 19 Android baseline")
    if args.target_sdk < 36:
        raise SystemExit("targetSdk must be >=36 for Google Play submissions from 2026-08-31")
    if args.compile_sdk < args.target_sdk:
        raise SystemExit("compileSdk must be >= targetSdk")

    root = Path(args.root).resolve()
    patch_android(root, args.android_id, args.min_sdk, args.compile_sdk, args.target_sdk)
    patch_ios(root, args.ios_id, args.ios_deployment_target)


if __name__ == "__main__":
    main()
