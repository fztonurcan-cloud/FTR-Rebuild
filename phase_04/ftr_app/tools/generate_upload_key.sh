#!/usr/bin/env bash
set -euo pipefail

command -v keytool >/dev/null || { echo "Java keytool is required (JDK 17+ recommended)."; exit 2; }
[[ -d android/app ]] || { echo "Run tools/bootstrap_android.sh first so android/app exists."; exit 2; }

KEYSTORE="android/app/ftr-upload-keystore.jks"
CERT="android/app/ftr-upload-certificate.pem"
ALIAS="ftr-upload"

if [[ -e "$KEYSTORE" ]]; then
  echo "Refusing to overwrite existing $KEYSTORE"
  exit 3
fi

read -rsp "Choose a strong keystore password: " STORE_PASS; echo
read -rsp "Repeat keystore password: " STORE_PASS_2; echo
[[ "$STORE_PASS" == "$STORE_PASS_2" ]] || { echo "Passwords do not match."; exit 4; }
[[ ${#STORE_PASS} -ge 12 ]] || { echo "Use at least 12 characters."; exit 4; }

keytool -genkeypair \
  -v \
  -keystore "$KEYSTORE" \
  -storetype PKCS12 \
  -storepass "$STORE_PASS" \
  -keypass "$STORE_PASS" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 4096 \
  -sigalg SHA256withRSA \
  -validity 10000 \
  -dname "CN=FTR Upload Key, OU=Android Release, O=FTR, C=TR"

keytool -exportcert -rfc \
  -keystore "$KEYSTORE" \
  -storepass "$STORE_PASS" \
  -alias "$ALIAS" \
  -file "$CERT"

cat > android/key.properties <<PROPS
storePassword=$STORE_PASS
keyPassword=$STORE_PASS
keyAlias=$ALIAS
storeFile=ftr-upload-keystore.jks
PROPS
chmod 600 android/key.properties "$KEYSTORE" 2>/dev/null || true
unset STORE_PASS STORE_PASS_2

echo
echo "Upload key created locally."
echo "Public certificate for Play Console reset request: $CERT"
echo "Private keystore (BACK THIS UP OFFLINE): $KEYSTORE"
echo "Do not upload the .jks file to Play Console and do not commit it to Git."
