#!/usr/bin/env python3
from pathlib import Path
import json, sys, xml.etree.ElementTree as ET
root=Path(sys.argv[1] if len(sys.argv)>1 else '.').resolve()
files={
 'config': root/'lib/core/config/app_config.dart',
 'service': root/'lib/services/auth_service.dart',
 'auth': root/'lib/features/auth/presentation/auth_screen.dart',
 'reset': root/'lib/features/auth/presentation/reset_password_screen.dart',
 'router': root/'lib/app/router.dart',
 'app': root/'lib/app/app.dart',
 'manifest': root/'android/app/src/main/AndroidManifest.xml',
 'gradle': root/'android/app/build.gradle.kts',
}
text={k:p.read_text(encoding='utf-8') for k,p in files.items()}
checks={
 'redirect_constant': "com.mobiroller.mobi743032079412://login-callback/" in text['config'],
 'reset_email_api': 'resetPasswordForEmail' in text['service'] and 'redirectTo: AppConfig.authRedirectUrl' in text['service'],
 'password_update_api': 'updateUser(UserAttributes(password: password))' in text['service'],
 'auth_state_stream': 'Stream<AuthState> get authStates' in text['service'],
 'forgot_password_ui': 'Şifremi unuttum' in text['auth'] and '_sendPasswordReset' in text['auth'],
 'reset_screen': 'class ResetPasswordScreen' in text['reset'] and 'Şifreler eşleşmiyor.' in text['reset'],
 'reset_route': "path: '/reset-password'" in text['router'],
 'recovery_event_route': 'AuthChangeEvent.passwordRecovery' in text['app'] and "appRouter.go('/reset-password')" in text['app'],
 'android_deeplink': 'android:scheme="com.mobiroller.mobi743032079412"' in text['manifest'] and 'android:host="login-callback"' in text['manifest'],
 'release_signing_separate': 'create("release")' in text['gradle'] and 'signingConfigs.getByName("release")' in text['gradle'],
 'no_debug_release_signing': 'signingConfigs.getByName("debug")' not in text['gradle'],
 'no_embedded_secret': all(x not in ''.join(text.values()).lower() for x in ['service_role_key=', 'sb_secret_', 'storepassword=temppass']),
}
try:
    ET.parse(files['manifest'])
    checks['manifest_xml_valid']=True
except Exception:
    checks['manifest_xml_valid']=False
report={'ok': all(checks.values()), 'passed': sum(checks.values()), 'total': len(checks), 'checks': checks}
print(json.dumps(report, ensure_ascii=False, indent=2))
raise SystemExit(0 if report['ok'] else 1)
