#!/usr/bin/env bash
set -euo pipefail

if [[ -f "${1:-android_release.env}" ]]; then
  set -a
  source "${1:-android_release.env}"
  set +a
fi

: "${FTR_PACKAGE_IDENTITY_CONFIRMED:?Set to YES only after Play Console signing/package continuity is verified.}"
: "${FTR_ANDROID_APPLICATION_ID:?Set final Android applicationId.}"
: "${FTR_PLAY_HIGHEST_VERSION_CODE:?Set the highest versionCode visible in Play Console.}"
: "${FTR_ANDROID_VERSION_CODE:?Set the next versionCode; it must be greater than the Play value.}"
: "${FTR_ANDROID_VERSION_NAME:?Set release versionName, e.g. 4.0.0.}"

python3 tools/android_release_gate.py \
  --root . \
  --identity-confirmed "$FTR_PACKAGE_IDENTITY_CONFIRMED" \
  --android-id "$FTR_ANDROID_APPLICATION_ID" \
  --play-highest-version-code "$FTR_PLAY_HIGHEST_VERSION_CODE" \
  --next-version-code "$FTR_ANDROID_VERSION_CODE" \
  --version-name "$FTR_ANDROID_VERSION_NAME" \
  --expect-legacy-id "${FTR_EXPECT_LEGACY_ANDROID_ID:-}"

command -v flutter >/dev/null || { echo 'Flutter SDK is not installed or not on PATH.'; exit 2; }
command -v dart >/dev/null || { echo 'Dart SDK is not available through Flutter/PATH.'; exit 2; }

FLUTTER_VERSION="$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"
python3 - "$FLUTTER_VERSION" <<'PY'
import re, sys

def numeric(v: str):
    parts = [int(x) for x in re.findall(r'\d+', v)[:3]]
    return tuple((parts + [0, 0, 0])[:3])

if numeric(sys.argv[1]) < (3, 47, 0):
    raise SystemExit(f'Flutter 3.47.0+ required; found {sys.argv[1]}')
PY

if [[ ! -d android ]]; then
  flutter create --platforms=android --project-name=ftr_app .
fi

python3 tools/configure_android.py \
  --root . \
  --android-id "$FTR_ANDROID_APPLICATION_ID" \
  --min-sdk 24 \
  --compile-sdk 36 \
  --target-sdk 36

flutter pub get
python3 tools/build_preflight.py --root . --strict --platform android
flutter analyze
flutter test

echo "Android bootstrap/analyze/test passed. Build with --build-number=$FTR_ANDROID_VERSION_CODE --build-name=$FTR_ANDROID_VERSION_NAME after signing configuration is ready."
