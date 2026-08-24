$ErrorActionPreference = 'Stop'

$envFile = if ($args.Count -gt 0) { $args[0] } else { "android_release.env" }
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
      $parts = $line -split '=', 2
      if ($parts.Count -eq 2) { [Environment]::SetEnvironmentVariable($parts[0], $parts[1], 'Process') }
    }
  }
}

$required = @(
  'FTR_PACKAGE_IDENTITY_CONFIRMED',
  'FTR_ANDROID_APPLICATION_ID',
  'FTR_PLAY_HIGHEST_VERSION_CODE',
  'FTR_ANDROID_VERSION_CODE',
  'FTR_ANDROID_VERSION_NAME'
)
foreach ($name in $required) {
  if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Set $name before Android bootstrap." }
}

$gateArgs = @(
  'tools/android_release_gate.py', '--root', '.',
  '--identity-confirmed', $env:FTR_PACKAGE_IDENTITY_CONFIRMED,
  '--android-id', $env:FTR_ANDROID_APPLICATION_ID,
  '--play-highest-version-code', $env:FTR_PLAY_HIGHEST_VERSION_CODE,
  '--next-version-code', $env:FTR_ANDROID_VERSION_CODE,
  '--version-name', $env:FTR_ANDROID_VERSION_NAME
)
if ($env:FTR_EXPECT_LEGACY_ANDROID_ID) { $gateArgs += @('--expect-legacy-id', $env:FTR_EXPECT_LEGACY_ANDROID_ID) }
python @gateArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter SDK is not installed or not on PATH.' }
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw 'Dart SDK is not available through Flutter/PATH.' }

$machine = flutter --version --machine | ConvertFrom-Json
$parts = ($machine.frameworkVersion -split '[^0-9]+') | Where-Object { $_ -ne '' } | Select-Object -First 3
$found = [Version](($parts + @('0','0','0'))[0..2] -join '.')
if ($found -lt [Version]'3.47.0') { throw "Flutter 3.47.0+ required; found $($machine.frameworkVersion)" }

if (-not (Test-Path 'android')) { flutter create --platforms=android --project-name=ftr_app . }
python tools/configure_android.py --root . --android-id $env:FTR_ANDROID_APPLICATION_ID --min-sdk 24 --compile-sdk 36 --target-sdk 36
flutter pub get
python tools/build_preflight.py --root .
flutter analyze
flutter test
Write-Host "Android bootstrap/analyze/test passed. Build with --build-number=$env:FTR_ANDROID_VERSION_CODE --build-name=$env:FTR_ANDROID_VERSION_NAME after signing configuration is ready."
