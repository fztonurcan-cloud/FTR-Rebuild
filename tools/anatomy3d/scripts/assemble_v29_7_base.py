#!/usr/bin/env python3
"""Safely assemble the immutable FTR Akademi v29.7 APK from locked parts.

This tool never edits the source part files and never overwrites an existing
output. Every part must match its locked filename, byte size and SHA-256 before
the temporary output is atomically promoted. The concatenated APK must then
match the locked final byte size and SHA-256 exactly.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
from pathlib import Path

BASE_NAME = "FTR-Akademi-v29.7-BILDIRIM.apk"
BASE_SIZE = 1_133_611_894
BASE_SHA256 = "f541b238e40113c02de101a9b7059f6b192f8381eaffbd0357314ce25bdd715c"

PARTS = (
    (
        "FTR-Akademi-v29.7-BILDIRIM.apk.part00",
        262_144_000,
        "5363ab648f2781b1fc73766c0bc525c49beb9b6c6e1a2ca1ccf55f948da8a23e",
    ),
    (
        "FTR-Akademi-v29.7-BILDIRIM.apk.part01",
        262_144_000,
        "26db0b0717d1a0212c7f5f1b4f61146740c2db434feeb6c32a44bf9c1909c0dd",
    ),
    (
        "FTR-Akademi-v29.7-BILDIRIM.apk.part02",
        262_144_000,
        "de3f04ec60c7877b66c26e111781e83b476a7db4dd0234dad8a0c83a6d6c3358",
    ),
    (
        "FTR-Akademi-v29.7-BILDIRIM.apk.part03",
        262_144_000,
        "13cacf2407a721250f5a74e28c4746696e4296514ef2575b0f3ddb253fb03839",
    ),
    (
        "FTR-Akademi-v29.7-BILDIRIM.apk.part04",
        85_035_894,
        "5d296bad1f9fdf589388155df59797983c8d1dc053cfb3688e1de7cacc3efb65",
    ),
)

CHUNK_SIZE = 8 * 1024 * 1024


def contract() -> dict[str, object]:
    return {
        "base": {
            "file": BASE_NAME,
            "bytes": BASE_SIZE,
            "sha256": BASE_SHA256,
        },
        "parts": [
            {"file": name, "bytes": size, "sha256": digest}
            for name, size, digest in PARTS
        ],
    }


def validate_contract() -> None:
    names = [name for name, _, _ in PARTS]
    if len(names) != 5 or len(names) != len(set(names)):
        raise SystemExit("Internal v29.7 part contract is invalid")
    if sum(size for _, size, _ in PARTS) != BASE_SIZE:
        raise SystemExit("Internal v29.7 part sizes do not sum to locked base size")
    for name, size, digest in PARTS:
        if size <= 0:
            raise SystemExit(f"Invalid locked part size for {name}")
        if len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
            raise SystemExit(f"Invalid locked SHA-256 for {name}")
    if len(BASE_SHA256) != 64:
        raise SystemExit("Invalid locked final SHA-256")


def assemble(parts_dir: Path, output: Path) -> dict[str, object]:
    validate_contract()
    parts_dir = parts_dir.resolve()
    output = output.resolve()

    if not parts_dir.is_dir():
        raise SystemExit(f"Parts directory not found: {parts_dir}")
    if output.exists():
        raise SystemExit(f"Refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    resolved_parts: list[tuple[Path, str, int, str]] = []
    for name, expected_size, expected_hash in PARTS:
        path = parts_dir / name
        if not path.is_file():
            raise SystemExit(f"Required v29.7 part not found: {path}")
        actual_size = path.stat().st_size
        if actual_size != expected_size:
            raise SystemExit(
                f"Refusing v29.7 part with wrong size: {name}; "
                f"expected={expected_size} actual={actual_size}"
            )
        resolved_parts.append((path, name, expected_size, expected_hash))

    temp_path: Path | None = None
    final_digest = hashlib.sha256()
    written = 0
    verified_parts: list[dict[str, object]] = []

    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            prefix=f".{output.name}.",
            suffix=".tmp",
            dir=output.parent,
            delete=False,
        ) as target:
            temp_path = Path(target.name)

            for path, name, expected_size, expected_hash in resolved_parts:
                part_digest = hashlib.sha256()
                part_bytes = 0
                with path.open("rb") as source:
                    for chunk in iter(lambda: source.read(CHUNK_SIZE), b""):
                        part_digest.update(chunk)
                        final_digest.update(chunk)
                        target.write(chunk)
                        part_bytes += len(chunk)
                        written += len(chunk)

                actual_hash = part_digest.hexdigest()
                if part_bytes != expected_size:
                    raise SystemExit(
                        f"Part changed while reading: {name}; "
                        f"expected bytes={expected_size} read={part_bytes}"
                    )
                if actual_hash != expected_hash:
                    raise SystemExit(
                        f"Refusing v29.7 part with wrong SHA-256: {name}; "
                        f"expected={expected_hash} actual={actual_hash}"
                    )
                verified_parts.append(
                    {
                        "file": name,
                        "bytes": part_bytes,
                        "sha256": actual_hash,
                        "verified": True,
                    }
                )

            target.flush()
            os.fsync(target.fileno())

        final_hash = final_digest.hexdigest()
        if written != BASE_SIZE:
            raise SystemExit(
                f"Assembled v29.7 size mismatch: expected={BASE_SIZE} actual={written}"
            )
        if final_hash != BASE_SHA256:
            raise SystemExit(
                f"Assembled v29.7 SHA-256 mismatch: "
                f"expected={BASE_SHA256} actual={final_hash}"
            )
        if temp_path is None or temp_path.stat().st_size != BASE_SIZE:
            raise SystemExit("Temporary assembled APK failed final size verification")

        os.replace(temp_path, output)
        temp_path = None

        return {
            "status": "PASS",
            "immutable_source_parts": True,
            "output_overwrite_allowed": False,
            "parts": verified_parts,
            "output": {
                "file": output.name,
                "bytes": written,
                "sha256": final_hash,
            },
        }
    finally:
        if temp_path is not None:
            try:
                temp_path.unlink(missing_ok=True)
            except OSError:
                pass


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fail-closed assembler for the immutable FTR Akademi v29.7 base APK"
    )
    parser.add_argument("--parts-dir", type=Path, help="Directory containing the five locked v29.7 parts")
    parser.add_argument("--output", type=Path, help=f"New output APK path; recommended name: {BASE_NAME}")
    parser.add_argument(
        "--print-contract",
        action="store_true",
        help="Print the locked v29.7 part/base contract and exit without reading files",
    )
    args = parser.parse_args()

    validate_contract()
    if args.print_contract:
        print(json.dumps(contract(), indent=2))
        return
    if args.parts_dir is None or args.output is None:
        parser.error("--parts-dir and --output are required unless --print-contract is used")

    result = assemble(args.parts_dir, args.output)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
