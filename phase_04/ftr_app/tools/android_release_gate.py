#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ANDROID_ID_RE = re.compile(r'^[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+$')
PUBSPEC_VERSION_RE = re.compile(r'^version:\s*([^+\s]+)\+([0-9]+)\s*$', re.M)
GRADLE_APPLICATION_ID_RE = re.compile(r'\bapplicationId\s*=\s*[\"\']([^\"\']+)[\"\']')


def parse_int(name: str, value: str) -> int:
    if not re.fullmatch(r'[0-9]+', value or ''):
        raise SystemExit(f'{name} must be a non-negative integer')
    return int(value)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--root', default='.')
    p.add_argument('--identity-confirmed', required=True)
    p.add_argument('--android-id', required=True)
    p.add_argument('--play-highest-version-code', required=True)
    p.add_argument('--next-version-code', required=True)
    p.add_argument('--version-name', required=True)
    p.add_argument('--expect-legacy-id', default='')
    args = p.parse_args()

    errors: list[str] = []
    if args.identity_confirmed != 'YES':
        errors.append('Package/signing continuity is not explicitly confirmed.')
    if not ANDROID_ID_RE.fullmatch(args.android_id):
        errors.append('Android applicationId is invalid.')
    if args.expect_legacy_id and args.android_id != args.expect_legacy_id:
        errors.append('Configured applicationId differs from the explicitly expected legacy package.')

    highest = parse_int('play-highest-version-code', args.play_highest_version_code)
    nxt = parse_int('next-version-code', args.next_version_code)
    if nxt <= highest:
        errors.append(f'next versionCode must be greater than Play highest versionCode ({highest}).')
    if not re.fullmatch(r'[0-9]+(?:\.[0-9A-Za-z-]+){1,3}', args.version_name):
        errors.append('version-name must be a dotted release identifier, e.g. 4.0.0.')

    root = Path(args.root).resolve()
    android_present = (root / 'android').is_dir()

    source_application_id = None
    gradle_path = root / 'android' / 'app' / 'build.gradle.kts'
    if gradle_path.is_file():
        gradle_text = gradle_path.read_text(encoding='utf-8', errors='ignore')
        m = GRADLE_APPLICATION_ID_RE.search(gradle_text)
        source_application_id = m.group(1) if m else None
        if source_application_id != args.android_id:
            errors.append(
                f'Android source applicationId mismatch: expected {args.android_id!r}, found {source_application_id!r}.'
            )
    else:
        errors.append('android/app/build.gradle.kts is missing.')

    source_version_name = None
    source_version_code = None
    pubspec_path = root / 'pubspec.yaml'
    if pubspec_path.is_file():
        pubspec_text = pubspec_path.read_text(encoding='utf-8', errors='ignore')
        m = PUBSPEC_VERSION_RE.search(pubspec_text)
        if m:
            source_version_name = m.group(1)
            source_version_code = int(m.group(2))
        if source_version_name != args.version_name or source_version_code != nxt:
            errors.append(
                'pubspec version mismatch: '
                f'expected {args.version_name}+{nxt}, found {source_version_name}+{source_version_code}.'
            )
    else:
        errors.append('pubspec.yaml is missing.')

    report = {
        'ok': not errors,
        'identity_confirmed': args.identity_confirmed == 'YES',
        'android_application_id': args.android_id,
        'expected_legacy_application_id': args.expect_legacy_id or None,
        'play_highest_version_code': highest,
        'next_version_code': nxt,
        'version_name': args.version_name,
        'android_platform_present': android_present,
        'source_application_id': source_application_id,
        'source_version_name': source_version_name,
        'source_version_code': source_version_code,
        'errors': errors,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 2


if __name__ == '__main__':
    raise SystemExit(main())
