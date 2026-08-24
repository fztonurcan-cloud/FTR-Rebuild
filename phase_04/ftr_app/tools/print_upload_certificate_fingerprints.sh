#!/usr/bin/env bash
set -euo pipefail
CERT="${1:-android/app/ftr-upload-certificate.pem}"
[[ -f "$CERT" ]] || { echo "Certificate not found: $CERT"; exit 2; }
keytool -printcert -file "$CERT" | grep -E 'SHA1:|SHA256:'
