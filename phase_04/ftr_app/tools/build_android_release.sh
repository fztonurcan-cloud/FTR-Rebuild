#!/usr/bin/env bash
set -euo pipefail
set -a
source "${1:-android_release.env}"
set +a

python3 tools/android_release_gate.py \
  --root . \
  --identity-confirmed "$FTR_PACKAGE_IDENTITY_CONFIRMED" \
  --android-id "$FTR_ANDROID_APPLICATION_ID" \
  --play-highest-version-code "$FTR_PLAY_HIGHEST_VERSION_CODE" \
  --next-version-code "$FTR_ANDROID_VERSION_CODE" \
  --version-name "$FTR_ANDROID_VERSION_NAME" \
  --expect-legacy-id "$FTR_EXPECT_LEGACY_ANDROID_ID"

[[ -d android ]] || { echo "Android platform missing. Run tools/bootstrap_android.sh first."; exit 2; }
[[ -f android/key.properties ]] || { echo "Signing config missing. Generate/reset upload key first."; exit 2; }
[[ -f android/app/ftr-upload-keystore.jks ]] || { echo "Upload keystore missing."; exit 2; }

python3 tools/configure_android_signing.py --root .
python3 tools/release_signing_gate.py --root .
python3 tools/build_preflight.py --root . --strict --platform android
python3 tools/test_play_policy_gate.py
python3 tools/play_policy_gate.py
flutter analyze --no-fatal-infos
flutter test

DART_DEFINES=()
[[ -n "${SUPABASE_URL:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
[[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}")
[[ -n "${PLAY_MONTHLY_PRODUCT_ID:-}" ]] && DART_DEFINES+=("--dart-define=PLAY_MONTHLY_PRODUCT_ID=${PLAY_MONTHLY_PRODUCT_ID}")
[[ -n "${PLAY_YEARLY_PRODUCT_ID:-}" ]] && DART_DEFINES+=("--dart-define=PLAY_YEARLY_PRODUCT_ID=${PLAY_YEARLY_PRODUCT_ID}")

flutter build appbundle --release \
  --build-name="$FTR_ANDROID_VERSION_NAME" \
  --build-number="$FTR_ANDROID_VERSION_CODE" \
  "${DART_DEFINES[@]}"

echo "AAB ready: build/app/outputs/bundle/release/app-release.aab"
