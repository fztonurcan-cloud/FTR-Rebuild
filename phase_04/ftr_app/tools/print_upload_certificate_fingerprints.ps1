$ErrorActionPreference = "Stop"
$cert = if ($args.Count -gt 0) { $args[0] } else { "android/app/ftr-upload-certificate.pem" }
if (-not (Test-Path $cert)) { throw "Certificate not found: $cert" }
& keytool -printcert -file $cert | Select-String -Pattern 'SHA1:|SHA256:'
