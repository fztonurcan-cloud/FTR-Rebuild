#!/usr/bin/env bash
set -euo pipefail

: "${FTR_PACKAGE_IDENTITY_CONFIRMED:?Set FTR_PACKAGE_IDENTITY_CONFIRMED=YES only after package/signing continuity is resolved.}"
[[ "$FTR_PACKAGE_IDENTITY_CONFIRMED" == "YES" ]] || { echo "FTR_PACKAGE_IDENTITY_CONFIRMED must equal YES."; exit 2; }
: "${FTR_ANDROID_APPLICATION_ID:?Set FTR_ANDROID_APPLICATION_ID after Play Console package/signing continuity is resolved.}"
: "${FTR_IOS_BUNDLE_ID:?Set FTR_IOS_BUNDLE_ID before generating iOS platform files.}"

command -v flutter >/dev/null || { echo "Flutter SDK is not installed or not on PATH."; exit 2; }
command -v dart >/dev/null || { echo "Dart SDK is not available through Flutter/PATH."; exit 2; }

FLUTTER_VERSION="$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"
python3 - "$FLUTTER_VERSION" <<'PY'
import re, sys

def numeric(v: str):
    parts = [int(x) for x in re.findall(r'\d+', v)[:3]]
    return tuple((parts + [0, 0, 0])[:3])

found = numeric(sys.argv[1])
required = (3, 47, 0)
if found < required:
    raise SystemExit(f"Flutter 3.47.0+ required; found {sys.argv[1]}")
PY

if [[ ! -d android || ! -d ios ]]; then
  flutter create --platforms=android,ios --project-name=ftr_app .
fi

python3 tools/configure_platforms.py \
  --root . \
  --android-id "$FTR_ANDROID_APPLICATION_ID" \
  --ios-id "$FTR_IOS_BUNDLE_ID" \
  --min-sdk 24 \
  --compile-sdk 36 \
  --target-sdk 36 \
  --ios-deployment-target 13.0

flutter pub get
python3 tools/build_preflight.py --root . --strict
flutter analyze
flutter test

echo "Platform bootstrap/analyze/test passed. Release signing and Play Console configuration are still separate gates."
