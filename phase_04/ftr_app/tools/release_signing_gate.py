#!/usr/bin/env python3
from __future__ import annotations
import argparse, json
from pathlib import Path


def parse_properties(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for raw in path.read_text(encoding='utf-8').splitlines():
        line = raw.strip()
        if not line or line.startswith('#') or '=' not in line:
            continue
        k, v = line.split('=', 1)
        out[k.strip()] = v.strip()
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--root', default='.')
    args = p.parse_args()
    root = Path(args.root).resolve()
    props_path = root / 'android' / 'key.properties'
    gradle_kts = root / 'android' / 'app' / 'build.gradle.kts'
    gradle_groovy = root / 'android' / 'app' / 'build.gradle'

    report: dict[str, object] = {
        'key_properties_present': props_path.is_file(),
        'keystore_present': False,
        'required_property_keys_present': False,
        'release_signing_config_present': False,
        'release_build_uses_release_signing': False,
        'debug_signing_reference_in_release': False,
        'ok': False,
    }

    if not props_path.is_file():
        print(json.dumps(report, indent=2))
        return 2

    props = parse_properties(props_path)
    required = ('storeFile', 'storePassword', 'keyAlias', 'keyPassword')
    report['required_property_keys_present'] = all(bool(props.get(k)) for k in required)
    store_file = props.get('storeFile', '')
    if store_file:
        store_path = Path(store_file)
        if not store_path.is_absolute():
            store_path = root / 'android' / 'app' / store_path
        report['keystore_present'] = store_path.is_file()
        report['keystore_path'] = str(store_path)

    gradle_path = gradle_kts if gradle_kts.is_file() else gradle_groovy
    if not gradle_path.is_file():
        report['error'] = 'Android app Gradle file missing'
        print(json.dumps(report, indent=2))
        return 2

    text = gradle_path.read_text(encoding='utf-8')
    if gradle_path.suffix == '.kts':
        report['release_signing_config_present'] = 'create("release")' in text
        report['release_build_uses_release_signing'] = 'signingConfig = signingConfigs.getByName("release")' in text
        report['debug_signing_reference_in_release'] = 'signingConfig = signingConfigs.getByName("debug")' in text
    else:
        report['release_signing_config_present'] = 'signingConfigs {' in text and 'release {' in text
        report['release_build_uses_release_signing'] = 'signingConfig signingConfigs.release' in text or 'signingConfig = signingConfigs.release' in text
        report['debug_signing_reference_in_release'] = 'signingConfig signingConfigs.debug' in text or 'signingConfig = signingConfigs.debug' in text

    report['ok'] = bool(
        report['required_property_keys_present']
        and report['keystore_present']
        and report['release_signing_config_present']
        and report['release_build_uses_release_signing']
        and not report['debug_signing_reference_in_release']
    )
    print(json.dumps(report, indent=2))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
