#!/usr/bin/env bash
set -euo pipefail
# Live runtime always uses Supabase-backed content; mock content is disabled.
flutter run \
  --dart-define=SUPABASE_URL=https://dkawrwinmyjvkzioruki.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_fQrP8FQtglit057xrYngtQ_M_ZoZQEl \
  --dart-define=USE_MOCK_CONTENT=false
