#!/usr/bin/env python3
from pathlib import Path
import json, sys

root = Path(__file__).resolve().parents[1]
auth = (root / 'lib/services/auth_service.dart').read_text(encoding='utf-8')
screen = (root / 'lib/features/account/presentation/account_privacy_screen.dart').read_text(encoding='utf-8')

checks = {
    'exact_server_confirmation': "'DELETE_MY_FTR_ACCOUNT'" in auth,
    'legacy_boolean_confirmation_removed': "body: const {'confirm': true}" not in auth,
    'password_reauthentication': '_client.auth.signInWithPassword' in auth and 'password: password' in auth,
    'fresh_session_used_for_delete': "'Bearer ${freshSession.accessToken}'" in auth,
    'same_user_guard': 'freshSession.user.id != user.id' in auth,
    'active_subscription_error_supported': 'active_google_play_subscription' in screen,
    'password_prompt_present': "labelText: 'Mevcut şifre'" in screen,
    'explicit_delete_phrase_ui': "'SİL'" in screen,
    'password_forwarded_to_service': 'deleteAccount(password: confirmation.password)' in screen,
    'successful_delete_not_reversed_by_signout_error': 'A local\n    // sign-out failure must not turn a successful deletion into a false error.' in auth,
    'network_failure_message_says_not_deleted': 'Hesabın silinmedi' in screen,
}

result = {
    'ok': all(checks.values()),
    'checks': checks,
    'passed': sum(checks.values()),
    'total': len(checks),
}
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(0 if result['ok'] else 2)
