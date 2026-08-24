$ErrorActionPreference = "Stop"
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter SDK is not installed or not on PATH." }
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw "Dart SDK is not available." }
$versionJson = flutter --version --machine | ConvertFrom-Json
$found = [version]$versionJson.frameworkVersion
if ($found -lt [version]"3.47.0") { throw "Flutter 3.47.0+ required; found $found" }
flutter pub get
python tools/build_preflight.py --root .
flutter analyze
flutter test
Write-Host "Source CI passed. Platform/package/signing gates are separate."
