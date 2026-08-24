$ErrorActionPreference = "Stop"
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) { throw "Java keytool is required (JDK 17+ recommended)." }
if (-not (Test-Path "android/app")) { throw "Run tools/bootstrap_android.ps1 first so android/app exists." }

$keystore = "android/app/ftr-upload-keystore.jks"
$cert = "android/app/ftr-upload-certificate.pem"
$alias = "ftr-upload"
if (Test-Path $keystore) { throw "Refusing to overwrite existing $keystore" }

$p1 = Read-Host "Choose a strong keystore password" -AsSecureString
$p2 = Read-Host "Repeat keystore password" -AsSecureString
$BSTR1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($p1)
$BSTR2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($p2)
try {
  $pass1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)
  $pass2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)
  if ($pass1 -ne $pass2) { throw "Passwords do not match." }
  if ($pass1.Length -lt 12) { throw "Use at least 12 characters." }

  & keytool -genkeypair -v -keystore $keystore -storetype PKCS12 -storepass $pass1 -keypass $pass1 -alias $alias -keyalg RSA -keysize 4096 -sigalg SHA256withRSA -validity 10000 -dname "CN=FTR Upload Key, OU=Android Release, O=FTR, C=TR"
  & keytool -exportcert -rfc -keystore $keystore -storepass $pass1 -alias $alias -file $cert

  @"
storePassword=$pass1
keyPassword=$pass1
keyAlias=$alias
storeFile=ftr-upload-keystore.jks
"@ | Set-Content -NoNewline android/key.properties

  Write-Host "Upload key created locally."
  Write-Host "Public certificate for Play Console reset request: $cert"
  Write-Host "Private keystore (BACK THIS UP OFFLINE): $keystore"
  Write-Host "Do not upload the .jks file to Play Console and do not commit it to Git."
}
finally {
  if ($BSTR1 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1) }
  if ($BSTR2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2) }
  Remove-Variable pass1,pass2 -ErrorAction SilentlyContinue
}
