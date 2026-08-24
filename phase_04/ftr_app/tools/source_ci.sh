#!/usr/bin/env bash
set -euo pipefail
command -v flutter >/dev/null || { echo "Flutter SDK is not installed or not on PATH."; exit 2; }
command -v dart >/dev/null || { echo "Dart SDK is not available through Flutter/PATH."; exit 2; }
FLUTTER_VERSION="$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"
python3 - "$FLUTTER_VERSION" <<'PY'
import re, sys
parts=[int(x) for x in re.findall(r'\d+', sys.argv[1])[:3]]
found=tuple((parts+[0,0,0])[:3])
if found < (3,47,0):
    raise SystemExit(f"Flutter 3.47.0+ required; found {sys.argv[1]}")
PY
flutter pub get
python3 tools/build_preflight.py --root .
flutter analyze
flutter test
echo "Source CI passed. Platform/package/signing gates are separate."
