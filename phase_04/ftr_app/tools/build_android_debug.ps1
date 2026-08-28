$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter SDK is not installed or not on PATH.'
}
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  throw 'Dart SDK is not available through Flutter/PATH.'
}

python tools/android_release_gate.py --root . --identity-confirmed YES --android-id com.mobiroller.mobi743032079412 --play-highest-version-code 24 --next-version-code 25 --version-name 4.0.0 --expect-legacy-id com.mobiroller.mobi743032079412
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/build_preflight.py --root . --strict --platform android
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/play_policy_gate.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$defines = @()
if ($env:SUPABASE_URL) { $defines += "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)" }
if ($env:SUPABASE_PUBLISHABLE_KEY) { $defines += "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($env:SUPABASE_PUBLISHABLE_KEY)" }
if ($env:PLAY_MONTHLY_PRODUCT_ID) { $defines += "--dart-define=PLAY_MONTHLY_PRODUCT_ID=$($env:PLAY_MONTHLY_PRODUCT_ID)" }
if ($env:PLAY_YEARLY_PRODUCT_ID) { $defines += "--dart-define=PLAY_YEARLY_PRODUCT_ID=$($env:PLAY_YEARLY_PRODUCT_ID)" }
if ($env:FTR_DEBUG_USE_MOCK_CONTENT -eq 'YES') { $defines += '--dart-define=USE_MOCK_CONTENT=true' }
if ($env:FTR_DEBUG_INTERNAL_REVIEW_PREVIEW -eq 'YES') { $defines += '--dart-define=INTERNAL_REVIEW_PREVIEW=true' }

flutter build apk --debug --build-name=4.0.0 --build-number=25 @defines
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
New-Item -ItemType Directory -Force -Path dist | Out-Null
Copy-Item build/app/outputs/flutter-apk/app-debug.apk dist/FTR-debug-4.0.0-25.apk -Force
$hash = (Get-FileHash dist/FTR-debug-4.0.0-25.apk -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  FTR-debug-4.0.0-25.apk" | Set-Content -Encoding ascii dist/FTR-debug-4.0.0-25.apk.sha256
Copy-Item pubspec.lock dist/pubspec.lock -Force
$lockHash = (Get-FileHash dist/pubspec.lock -Algorithm SHA256).Hash.ToLowerInvariant()
"$lockHash  pubspec.lock" | Set-Content -Encoding ascii dist/pubspec.lock.sha256
Write-Host 'Debug APK ready: dist/FTR-debug-4.0.0-25.apk'
