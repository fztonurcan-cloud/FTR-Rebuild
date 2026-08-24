#!/usr/bin/env python3
from pathlib import Path
import json, sys
root = Path(__file__).resolve().parents[1]
script = (root / 'tools' / 'build_android_release.sh').read_text(encoding='utf-8')
required = [
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'PLAY_MONTHLY_PRODUCT_ID',
    'PLAY_YEARLY_PRODUCT_ID',
]
checks = {
    'uses_dart_defines_array': 'DART_DEFINES=()' in script,
    'passes_array_to_appbundle': '"${DART_DEFINES[@]}"' in script,
}
for key in required:
    checks[f'define_{key.lower()}'] = f'--dart-define={key}=' in script
ok = all(checks.values())
print(json.dumps({'ok':ok, **checks}, indent=2))
sys.exit(0 if ok else 1)
