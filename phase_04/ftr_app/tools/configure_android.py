#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Reuse the battle-tested Android patcher while keeping Android bootstrap
# independent from an iOS bundle identifier.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from configure_platforms import ANDROID_ID_RE, patch_android  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.')
    parser.add_argument('--android-id', required=True)
    parser.add_argument('--min-sdk', type=int, default=24)
    parser.add_argument('--compile-sdk', type=int, default=36)
    parser.add_argument('--target-sdk', type=int, default=36)
    args = parser.parse_args()

    if not ANDROID_ID_RE.fullmatch(args.android_id):
        raise SystemExit(f'Invalid Android applicationId: {args.android_id!r}')
    if args.min_sdk < 24:
        raise SystemExit('minSdk must be >=24 because in_app_purchase 3.3.0 supports Android SDK 24+')
    if args.target_sdk < 36:
        raise SystemExit('targetSdk must be >=36 for Google Play submissions from 2026-08-31')
    if args.compile_sdk < 36 or args.compile_sdk < args.target_sdk:
        raise SystemExit('compileSdk must be >=36 and >= targetSdk')

    patch_android(Path(args.root).resolve(), args.android_id, args.min_sdk, args.compile_sdk, args.target_sdk)


if __name__ == '__main__':
    main()
