#!/usr/bin/env python3
from __future__ import annotations
import argparse
from pathlib import Path

KTS_TOP = '''import java.util.Properties\nimport java.io.FileInputStream\n\nval keystoreProperties = Properties()\nval keystorePropertiesFile = rootProject.file("key.properties")\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n}\n\n'''
KTS_BLOCK = '''\n    signingConfigs {\n        create("release") {\n            if (!keystorePropertiesFile.exists()) {\n                throw GradleException("android/key.properties is required for release signing")\n            }\n            keyAlias = keystoreProperties["keyAlias"] as String\n            keyPassword = keystoreProperties["keyPassword"] as String\n            storeFile = file(keystoreProperties["storeFile"] as String)\n            storePassword = keystoreProperties["storePassword"] as String\n        }\n    }\n'''
GROOVY_TOP = '''def keystoreProperties = new Properties()\ndef keystorePropertiesFile = rootProject.file('key.properties')\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n}\n\n'''
GROOVY_BLOCK = '''\n    signingConfigs {\n        release {\n            if (!keystorePropertiesFile.exists()) {\n                throw new GradleException('android/key.properties is required for release signing')\n            }\n            keyAlias keystoreProperties['keyAlias']\n            keyPassword keystoreProperties['keyPassword']\n            storeFile file(keystoreProperties['storeFile'])\n            storePassword keystoreProperties['storePassword']\n        }\n    }\n'''

def patch_kts(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    if 'val keystoreProperties = Properties()' not in text:
        text = KTS_TOP + text
    if 'create("release")' not in text:
        marker = '\n    buildTypes {'
        if marker not in text:
            raise SystemExit('Could not find buildTypes block in Kotlin Gradle file')
        text = text.replace(marker, KTS_BLOCK + marker, 1)
    old = 'signingConfig = signingConfigs.getByName("debug")'
    new = 'signingConfig = signingConfigs.getByName("release")'
    if old in text:
        text = text.replace(old, new, 1)
    elif new not in text:
        raise SystemExit('Could not safely configure Kotlin release signingConfig')
    path.write_text(text, encoding='utf-8')

def patch_groovy(path: Path) -> None:
    text = path.read_text(encoding='utf-8')
    if 'def keystoreProperties = new Properties()' not in text:
        text = GROOVY_TOP + text
    if "keyAlias keystoreProperties['keyAlias']" not in text:
        marker = '\n    buildTypes {'
        if marker not in text:
            raise SystemExit('Could not find buildTypes block in Groovy Gradle file')
        text = text.replace(marker, GROOVY_BLOCK + marker, 1)
    old_candidates = ['signingConfig signingConfigs.debug', 'signingConfig = signingConfigs.debug']
    for old in old_candidates:
        if old in text:
            text = text.replace(old, 'signingConfig signingConfigs.release', 1)
            break
    if 'signingConfig signingConfigs.release' not in text:
        raise SystemExit('Could not safely configure Groovy release signingConfig')
    path.write_text(text, encoding='utf-8')

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.')
    args = parser.parse_args()
    root = Path(args.root).resolve()
    kts = root / 'android/app/build.gradle.kts'
    groovy = root / 'android/app/build.gradle'
    if kts.is_file():
        patch_kts(kts)
    elif groovy.is_file():
        patch_groovy(groovy)
    else:
        raise SystemExit('Android app Gradle file not found')
    print('Android release signing configuration installed.')

if __name__ == '__main__':
    main()
