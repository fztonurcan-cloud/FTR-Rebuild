$ErrorActionPreference = "Stop"
$envFile = if ($args.Count -gt 0) { $args[0] } else { "android_release.env" }
if (-not (Test-Path $envFile)) { throw "Release environment file not found: $envFile" }
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -and -not $line.StartsWith('#')) {
    $parts = $line -split '=', 2
    if ($parts.Count -eq 2) { [Environment]::SetEnvironmentVariable($parts[0], $parts[1], 'Process') }
  }
}

$requiredValues = @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'PLAY_MONTHLY_PRODUCT_ID', 'PLAY_YEARLY_PRODUCT_ID')
foreach ($name in $requiredValues) {
  $value = [Environment]::GetEnvironmentVariable($name, 'Process')
  if ([string]::IsNullOrWhiteSpace($value)) { throw "Missing required release value: $name" }
}
if ($env:PLAY_MONTHLY_PRODUCT_ID -eq $env:PLAY_YEARLY_PRODUCT_ID) {
  throw 'Monthly and yearly Play product IDs must be different.'
}

$gateArgs = @(
  'tools/android_release_gate.py', '--root', '.',
  '--identity-confirmed', $env:FTR_PACKAGE_IDENTITY_CONFIRMED,
  '--android-id', $env:FTR_ANDROID_APPLICATION_ID,
  '--play-highest-version-code', $env:FTR_PLAY_HIGHEST_VERSION_CODE,
  '--next-version-code', $env:FTR_ANDROID_VERSION_CODE,
  '--version-name', $env:FTR_ANDROID_VERSION_NAME,
  '--expect-legacy-id', $env:FTR_EXPECT_LEGACY_ANDROID_ID
)
python @gateArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not (Test-Path 'android')) { throw 'Android platform missing. Run tools/bootstrap_android.ps1 first.' }
if (-not (Test-Path 'android/key.properties')) { throw 'Signing config missing. Generate/reset upload key first.' }
if (-not (Test-Path 'android/app/ftr-upload-keystore.jks')) { throw 'Upload keystore missing.' }

python tools/configure_android_signing.py --root .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/release_signing_gate.py --root .
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/build_preflight.py --root . --strict --platform android
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/test_play_policy_gate.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/play_policy_gate.py
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$defines = @(
  "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)",
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($env:SUPABASE_PUBLISHABLE_KEY)",
  "--dart-define=PLAY_MONTHLY_PRODUCT_ID=$($env:PLAY_MONTHLY_PRODUCT_ID)",
  "--dart-define=PLAY_YEARLY_PRODUCT_ID=$($env:PLAY_YEARLY_PRODUCT_ID)"
)

flutter build appbundle --release --build-name=$env:FTR_ANDROID_VERSION_NAME --build-number=$env:FTR_ANDROID_VERSION_CODE @defines
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'AAB ready: build/app/outputs/bundle/release/app-release.aab'
