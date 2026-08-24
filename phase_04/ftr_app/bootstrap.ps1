# Run from this directory after installing Flutter 3.47 stable.
# This creates Android/iOS runner files without replacing the prepared Dart source.
flutter create . --org com.ftr --platforms android,ios
flutter pub get
Write-Host "Verify android/app/build.gradle(.kts): targetSdk = 36 before Play submission."
