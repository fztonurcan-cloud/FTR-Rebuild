#!/usr/bin/env bash
set -euo pipefail

command -v flutter >/dev/null || { echo "Flutter SDK is not installed or not on PATH."; exit 2; }
command -v dart >/dev/null || { echo "Dart SDK is not available through Flutter/PATH."; exit 2; }

python3 tools/android_release_gate.py \
  --root . \
  --identity-confirmed YES \
  --android-id com.mobiroller.mobi743032079412 \
  --play-highest-version-code 24 \
  --next-version-code 25 \
  --version-name 4.0.0 \
  --expect-legacy-id com.mobiroller.mobi743032079412

flutter pub get
python3 tools/build_preflight.py --root . --strict --platform android
flutter analyze
flutter test

DART_DEFINES=()
[[ -n "${SUPABASE_URL:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
[[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}")
[[ -n "${PLAY_MONTHLY_PRODUCT_ID:-}" ]] && DART_DEFINES+=("--dart-define=PLAY_MONTHLY_PRODUCT_ID=${PLAY_MONTHLY_PRODUCT_ID}")
[[ -n "${PLAY_YEARLY_PRODUCT_ID:-}" ]] && DART_DEFINES+=("--dart-define=PLAY_YEARLY_PRODUCT_ID=${PLAY_YEARLY_PRODUCT_ID}")
if [[ "${FTR_DEBUG_USE_MOCK_CONTENT:-NO}" == "YES" ]]; then
  DART_DEFINES+=("--dart-define=USE_MOCK_CONTENT=true")
fi

flutter build apk --debug \
  --build-name=4.0.0 \
  --build-number=25 \
  "${DART_DEFINES[@]}"

mkdir -p dist
cp build/app/outputs/flutter-apk/app-debug.apk dist/FTR-debug-4.0.0-25.apk
sha256sum dist/FTR-debug-4.0.0-25.apk > dist/FTR-debug-4.0.0-25.apk.sha256
cp pubspec.lock dist/pubspec.lock
sha256sum dist/pubspec.lock > dist/pubspec.lock.sha256

echo "Debug APK ready: dist/FTR-debug-4.0.0-25.apk"
