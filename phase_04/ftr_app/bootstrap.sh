#!/usr/bin/env bash
set -euo pipefail
flutter create . --org com.ftr --platforms android,ios
flutter pub get
echo "Verify android/app/build.gradle(.kts): targetSdk = 36 before Play submission."
