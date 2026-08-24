$ErrorActionPreference = "Stop"

if ($env:FTR_PACKAGE_IDENTITY_CONFIRMED -ne "YES") {
  throw "Set FTR_PACKAGE_IDENTITY_CONFIRMED=YES only after package/signing continuity is resolved."
}
if (-not $env:FTR_ANDROID_APPLICATION_ID) {
  throw "Set FTR_ANDROID_APPLICATION_ID after Play Console package/signing continuity is resolved."
}
if (-not $env:FTR_IOS_BUNDLE_ID) {
  throw "Set FTR_IOS_BUNDLE_ID before generating iOS platform files."
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter SDK is not installed or not on PATH."
}
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  throw "Dart SDK is not available."
}

$versionJson = flutter --version --machine | ConvertFrom-Json
$found = [version]$versionJson.frameworkVersion
$required = [version]"3.47.0"
if ($found -lt $required) {
  throw "Flutter 3.47.0+ required; found $found"
}

if (-not (Test-Path "android") -or -not (Test-Path "ios")) {
  flutter create --platforms=android,ios --project-name=ftr_app .
}

python tools/configure_platforms.py `
  --root . `
  --android-id $env:FTR_ANDROID_APPLICATION_ID `
  --ios-id $env:FTR_IOS_BUNDLE_ID `
  --min-sdk 24 `
  --compile-sdk 36 `
  --target-sdk 36 `
  --ios-deployment-target 13.0

flutter pub get
python tools/build_preflight.py --root . --strict
flutter analyze
flutter test

Write-Host "Platform bootstrap/analyze/test passed. Release signing and Play Console configuration are still separate gates."
