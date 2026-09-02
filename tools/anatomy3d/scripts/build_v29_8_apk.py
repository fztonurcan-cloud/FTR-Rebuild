#!/usr/bin/env python3
"""Build the isolated v29.8.1 simple 3D APK from the immutable v29.7 APK.

The script refuses any base APK that does not match the locked v29.7 size and
SHA-256. It changes only the host HTML bootstrap, adds the home-card bootstrap,
and adds the already-QA'd offline 3D Anatomy module. The original APK is never
opened for writing.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path


BASE_NAME = "FTR-Akademi-v29.7-BILDIRIM.apk"
BASE_SIZE = 1_133_611_894
BASE_SHA256 = "f541b238e40113c02de101a9b7059f6b192f8381eaffbd0357314ce25bdd715c"
EXPECTED_CERT_SHA256 = "8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2"
HOST_INDEX = "assets/app/index.html"
MODULE_PREFIX = "assets/app/anatomy3d/"
HOME_CSS = "assets/app/anatomy3d-home-card.css"
HOME_JS = "assets/app/anatomy3d-home-inject.js"
MODULE_FETCH = "assets/app/anatomy3d/android-asset-fetch.js"
MODULE_PHONE_CSS = "assets/app/anatomy3d/module-phone-fix.css"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(args: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None,
        capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=cwd,
        env=env,
        text=True,
        check=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.STDOUT if capture else None,
    )


def signing_values(path: Path) -> tuple[str, str]:
    alias = ""
    password = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        if raw.startswith("Alias:"):
            alias = raw.split(":", 1)[1].strip()
        elif raw.startswith("Store/Key Password:"):
            password = raw.split(":", 1)[1].strip()
    if not alias or not password:
        raise SystemExit("Signing metadata is missing Alias or Store/Key Password")
    return alias, password


def inject_host_bootstrap(source: str) -> str:
    css_tag = '<link rel="stylesheet" href="./anatomy3d-home-card.css" data-ftr-anatomy3d="v29.8.1">'
    js_tag = '<script defer src="./anatomy3d-home-inject.js" data-ftr-anatomy3d="v29.8.1"></script>'
    if "data-ftr-anatomy3d" in source:
        raise SystemExit("Host index already contains a 3D Anatomy bootstrap")
    if "</head>" not in source or "</body>" not in source:
        raise SystemExit("Host index is missing </head> or </body>")
    source = source.replace("</head>", f"  {css_tag}\n</head>", 1)
    source = source.replace("</body>", f"  {js_tag}\n</body>", 1)
    return source


def inject_module_bootstrap(source: str) -> str:
    fetch_tag = '<script src="./android-asset-fetch.js" data-ftr-android-asset-fetch="v29.8.1-simple"></script>'
    css_tag = '<link rel="stylesheet" href="./module-phone-fix.css" data-ftr-phone-layout="v29.8.1-simple">'
    if "android-asset-fetch.js" not in source:
        source = source.replace("</head>", f"  {fetch_tag}\n</head>", 1)
    if "module-phone-fix.css" not in source:
        source = source.replace("</head>", f"  {css_tag}\n</head>", 1)
    return source


def signature_entries(names: list[str]) -> list[str]:
    result = []
    for name in names:
        upper = name.upper()
        if upper == "META-INF/MANIFEST.MF" or re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", upper):
            result.append(name)
    return result


def validate_module(module_root: Path) -> list[Path]:
    required = [
        "index.html",
        "models/skeleton.glb",
        "models/muscular.glb",
        "models/ligaments.glb",
        "models/cardiovascular.glb",
        "data/structures.json",
        "licenses/ATTRIBUTION.txt",
        "licenses/Z-Anatomy-License.txt",
    ]
    missing = [item for item in required if not (module_root / item).is_file()]
    if missing:
        raise SystemExit(f"3D Anatomy module is incomplete: {missing}")
    return sorted(path for path in module_root.rglob("*") if path.is_file())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--artifact", type=Path, required=True,
                        help="Extracted v29.8 Actions artifact root")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--zipalign", type=Path, required=True)
    parser.add_argument("--apksigner", type=Path, required=True)
    parser.add_argument("--keystore", type=Path, required=True)
    parser.add_argument("--signing-metadata", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    base = args.base.resolve()
    artifact = args.artifact.resolve()
    output = args.output.resolve()
    report_path = args.report.resolve()
    module_root = artifact / "dist"
    source_root = Path(__file__).resolve().parent.parent
    integration_root = source_root / "integration"

    for path in [base, args.zipalign, args.apksigner, args.keystore, args.signing_metadata]:
        if not path.is_file():
            raise SystemExit(f"Required file not found: {path}")
    if base.stat().st_size != BASE_SIZE:
        raise SystemExit(f"Refusing non-v29.7 base size: {base.stat().st_size}")
    base_hash = sha256(base)
    if base_hash != BASE_SHA256:
        raise SystemExit(f"Refusing non-v29.7 base SHA-256: {base_hash}")

    module_files = validate_module(module_root)
    for path in [
        integration_root / "home-card.css",
        integration_root / "home-inject.js",
        integration_root / "module-phone-fix.css",
        source_root / "public" / "android-asset-fetch.js",
    ]:
        if not path.is_file():
            raise SystemExit(f"Integration file missing: {path}")

    with zipfile.ZipFile(base) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise SystemExit("Base APK contains duplicate ZIP entries")
        if HOST_INDEX not in names:
            raise SystemExit(f"Base APK is missing {HOST_INDEX}")
        original_index = archive.read(HOST_INDEX).decode("utf-8")
        original_payload = {
            item.filename: (item.file_size, item.CRC)
            for item in archive.infolist()
            if item.filename not in signature_entries(names)
        }

    output.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    alias, password = signing_values(args.signing_metadata)

    with tempfile.TemporaryDirectory(prefix="ftr-v29.8-") as temp_name:
        temp = Path(temp_name)
        stage = temp / "stage"
        work_apk = temp / "v29.8-unaligned.apk"
        aligned_apk = temp / "v29.8-aligned.apk"
        host_dir = stage / "assets" / "app"
        host_dir.mkdir(parents=True)
        shutil.copyfile(base, work_apk)

        (host_dir / "index.html").write_text(inject_host_bootstrap(original_index), encoding="utf-8")
        shutil.copyfile(integration_root / "home-card.css", host_dir / Path(HOME_CSS).name)
        shutil.copyfile(integration_root / "home-inject.js", host_dir / Path(HOME_JS).name)
        shutil.copytree(module_root, host_dir / "anatomy3d")
        module_index = host_dir / "anatomy3d" / "index.html"
        module_index.write_text(inject_module_bootstrap(module_index.read_text(encoding="utf-8")), encoding="utf-8")
        shutil.copyfile(source_root / "public" / "android-asset-fetch.js", stage / MODULE_FETCH)
        shutil.copyfile(integration_root / "module-phone-fix.css", stage / MODULE_PHONE_CSS)

        removals = signature_entries(names) + [HOST_INDEX]
        run(["zip", "-q", "-d", str(work_apk), *removals])
        run([
            "zip", "-q", "-9", "-D", "-r", str(work_apk),
            HOST_INDEX, HOME_CSS, HOME_JS, MODULE_PREFIX.rstrip("/"),
        ], cwd=stage)
        stored_assets = [
            MODULE_PREFIX + str(path.relative_to(module_root)).replace(os.sep, "/")
            for path in module_files
            if path.suffix.lower() in {".glb", ".wasm"}
        ]
        # Android WebView serves packaged binary assets most reliably when they
        # are not DEFLATE-compressed inside the APK. No model data is changed.
        run(["zip", "-q", "-d", str(work_apk), *stored_assets])
        run(["zip", "-q", "-0", "-D", str(work_apk), *stored_assets], cwd=stage)

        run([str(args.zipalign.resolve()), "-p", "-f", "4", str(work_apk), str(aligned_apk)])
        sign_env = os.environ.copy()
        sign_env["FTR_V29_8_KS_PASS"] = password
        run([
            str(args.apksigner.resolve()), "sign",
            "--ks", str(args.keystore.resolve()),
            "--ks-key-alias", alias,
            "--ks-pass", "env:FTR_V29_8_KS_PASS",
            "--key-pass", "env:FTR_V29_8_KS_PASS",
            "--v1-signing-enabled", "true",
            "--v2-signing-enabled", "true",
            "--v3-signing-enabled", "false",
            "--v4-signing-enabled", "false",
            "--out", str(output),
            str(aligned_apk),
        ], env=sign_env)

    verify = run([str(args.apksigner.resolve()), "verify", "--verbose", "--print-certs", str(output)], capture=True)
    verify_text = verify.stdout or ""
    cert_match = EXPECTED_CERT_SHA256 in re.sub(r"[^0-9A-Fa-f]", "", verify_text).lower()
    if not cert_match:
        raise SystemExit("Signed APK certificate does not match the locked FTR v41 certificate")
    run([str(args.zipalign.resolve()), "-c", "-p", "4", str(output)])

    with zipfile.ZipFile(output) as archive:
        output_names = archive.namelist()
        if len(output_names) != len(set(output_names)):
            raise SystemExit("Output APK contains duplicate ZIP entries")
        output_payload = {
            item.filename: (item.file_size, item.CRC)
            for item in archive.infolist()
            if item.filename not in signature_entries(output_names)
        }
        bad_entry = archive.testzip()
        if bad_entry:
            raise SystemExit(f"Output APK ZIP integrity failed at: {bad_entry}")
        wrongly_compressed = [
            name for name in stored_assets
            if archive.getinfo(name).compress_type != zipfile.ZIP_STORED
        ]
        if wrongly_compressed:
            raise SystemExit(f"Android binary assets are compressed: {wrongly_compressed}")

    expected_changed = {HOST_INDEX}
    added_expected = {HOME_CSS, HOME_JS, MODULE_FETCH, MODULE_PHONE_CSS} | {
        MODULE_PREFIX + str(path.relative_to(module_root)).replace(os.sep, "/")
        for path in module_files
    }
    changed_existing = sorted(
        name for name, value in original_payload.items()
        if name in output_payload and output_payload[name] != value
    )
    removed_existing = sorted(name for name in original_payload if name not in output_payload)
    added = sorted(name for name in output_payload if name not in original_payload)
    if set(changed_existing) != expected_changed:
        raise SystemExit(f"Unexpected changed existing payload: {changed_existing}")
    if removed_existing:
        raise SystemExit(f"Unexpected removed payload: {removed_existing}")
    if set(added) != added_expected:
        raise SystemExit("Added payload does not exactly match the locked 3D Anatomy integration")

    report = {
        "version": "v29.8.1-3d-simple",
        "status": "BUILD_STATIC_QA_PASS_PHONE_QA_REQUIRED",
        "base": {"file": BASE_NAME, "bytes": BASE_SIZE, "sha256": BASE_SHA256, "modified": False},
        "output": {"file": output.name, "bytes": output.stat().st_size, "sha256": sha256(output)},
        "package": "com.ftrakademi.preview3",
        "signer_cert_sha256": EXPECTED_CERT_SHA256,
        "v1_signature": "PASS",
        "v2_signature": "PASS",
        "zip_alignment": "PASS",
        "zip_integrity": "PASS",
        "duplicate_zip_entries": 0,
        "changed_existing_payload": changed_existing,
        "added_payload_count": len(added),
        "removed_existing_payload": removed_existing,
        "protected_scope": {
            "all_other_existing_entries_match_by_size_and_crc32": True,
            "lessons_quizzes_movement_program_favorites_notes_auth_supabase_notifications_ftr_ai_untouched": True,
        },
        "android_asset_binary_storage": "PASS",
        "physical_phone_qa": "PENDING_USER_RETEST",
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
