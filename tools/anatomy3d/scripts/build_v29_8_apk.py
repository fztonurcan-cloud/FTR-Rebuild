#!/usr/bin/env python3
"""Build a v29.9 static-atlas APK from the immutable v29.7 checkpoint.

The base APK is never modified in place. The script refuses any base that does
not exactly match the locked v29.7 size/SHA, injects only the 3D Anatomi home
bootstrap and the QA-approved static atlas module, then signs a new APK with the
existing locked certificate.
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
VERSION = "v29.9-static-atlas"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(args: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None,
        capture: bool = False) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args, cwd=cwd, env=env, text=True, check=True,
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
    css_tag = f'<link rel="stylesheet" href="./anatomy3d-home-card.css" data-ftr-anatomy3d="{VERSION}">'
    js_tag = f'<script defer src="./anatomy3d-home-inject.js" data-ftr-anatomy3d="{VERSION}"></script>'
    if "data-ftr-anatomy3d" in source:
        raise SystemExit("Host index already contains a 3D Anatomy bootstrap")
    if "</head>" not in source or "</body>" not in source:
        raise SystemExit("Host index is missing </head> or </body>")
    source = source.replace("</head>", f"  {css_tag}\n</head>", 1)
    source = source.replace("</body>", f"  {js_tag}\n</body>", 1)
    return source


def inject_module_bootstrap(source: str) -> str:
    fetch_tag = f'<script src="./android-asset-fetch.js" data-ftr-android-asset-fetch="{VERSION}"></script>'
    css_tag = f'<link rel="stylesheet" href="./module-phone-fix.css" data-ftr-phone-layout="{VERSION}">'
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
        "data/atlas-map.json",
        "atlas/muscle-front.png", "atlas/muscle-id.png",
        "atlas/bone-front.png", "atlas/bone-id.png",
        "atlas/ligament-front.png", "atlas/ligament-id.png",
        "atlas/vessel-front.png", "atlas/vessel-id.png",
        "atlas/nerve-front.png", "atlas/nerve-id.png",
        "licenses/ATTRIBUTION.txt",
        "licenses/Z-Anatomy-License.txt",
    ]
    missing = [item for item in required if not (module_root / item).is_file()]
    if missing:
        raise SystemExit(f"Static Anatomy module is incomplete: {missing}")

    atlas = json.loads((module_root / "data/atlas-map.json").read_text(encoding="utf-8"))
    if atlas.get("render_mode") != "static-layered-atlas":
        raise SystemExit("Module is not the locked static-layered-atlas architecture")
    policy = atlas.get("policy") or {}
    if policy.get("webgl") is not False or policy.get("runtime_3d_models") is not False or policy.get("continuous_render_loop") is not False:
        raise SystemExit(f"Static atlas performance contract missing: {policy}")
    if list(module_root.rglob("*.glb")):
        raise SystemExit("Runtime GLB files are forbidden in the v29.9 static atlas")
    return sorted(path for path in module_root.rglob("*") if path.is_file())


def verify_signing(apksigner: Path, output: Path) -> dict[str, object]:
    verify = run([str(apksigner.resolve()), "verify", "--verbose", "--print-certs", str(output)], capture=True)
    text = verify.stdout or ""

    def scheme(number: int) -> bool:
        pattern = rf"Verified using v{number} scheme[^:]*:\s*(true|false)"
        match = re.search(pattern, text, flags=re.IGNORECASE)
        if not match:
            raise SystemExit(f"apksigner output is missing explicit v{number} verification status")
        return match.group(1).lower() == "true"

    v1 = scheme(1)
    v2 = scheme(2)
    if not v1 or not v2:
        raise SystemExit(f"APK must verify with both v1 and v2 signatures; v1={v1}, v2={v2}")

    signer_count_match = re.search(r"Number of signers:\s*(\d+)", text, flags=re.IGNORECASE)
    if not signer_count_match:
        raise SystemExit("apksigner output is missing signer count")
    signer_count = int(signer_count_match.group(1))
    if signer_count != 1:
        raise SystemExit(f"Expected exactly one APK signer, found {signer_count}")

    cert_match = re.search(
        r"Signer #1 certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)",
        text,
        flags=re.IGNORECASE,
    )
    if not cert_match:
        raise SystemExit("apksigner output is missing signer certificate SHA-256")
    cert_sha256 = re.sub(r"[^0-9A-Fa-f]", "", cert_match.group(1)).lower()
    if cert_sha256 != EXPECTED_CERT_SHA256:
        raise SystemExit(
            "Signed APK certificate does not match the locked FTR v41 certificate: "
            f"{cert_sha256}"
        )

    return {
        "v1": v1,
        "v2": v2,
        "signer_count": signer_count,
        "certificate_sha256": cert_sha256,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--artifact", type=Path, required=True, help="Extracted v29.9 Actions artifact root")
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

    with tempfile.TemporaryDirectory(prefix="ftr-v29.9-static-") as temp_name:
        temp = Path(temp_name)
        stage = temp / "stage"
        work_apk = temp / "v29.9-unaligned.apk"
        aligned_apk = temp / "v29.9-aligned.apk"
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

        run([str(args.zipalign.resolve()), "-p", "-f", "4", str(work_apk), str(aligned_apk)])
        sign_env = os.environ.copy()
        sign_env["FTR_V29_9_KS_PASS"] = password
        run([
            str(args.apksigner.resolve()), "sign",
            "--ks", str(args.keystore.resolve()),
            "--ks-key-alias", alias,
            "--ks-pass", "env:FTR_V29_9_KS_PASS",
            "--key-pass", "env:FTR_V29_9_KS_PASS",
            "--v1-signing-enabled", "true",
            "--v2-signing-enabled", "true",
            "--v3-signing-enabled", "false",
            "--v4-signing-enabled", "false",
            "--out", str(output), str(aligned_apk),
        ], env=sign_env)

    signing = verify_signing(args.apksigner, output)
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
        output_index = archive.read(HOST_INDEX).decode("utf-8")
        module_index = archive.read(MODULE_PREFIX + "index.html").decode("utf-8")

    if output_index.count("data-ftr-anatomy3d") != 2:
        raise SystemExit("Host 3D Anatomy bootstrap is missing or duplicated")
    if "anatomy3d-home-card.css" not in output_index or "anatomy3d-home-inject.js" not in output_index:
        raise SystemExit("Host 3D Anatomy CSS/JS bootstrap is incomplete")
    if "android-asset-fetch.js" not in module_index or "module-phone-fix.css" not in module_index:
        raise SystemExit("3D Anatomy Android module bootstrap is incomplete")

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
        "version": VERSION,
        "status": "BUILD_STATIC_QA_PASS_PHONE_QA_REQUIRED",
        "base": {"file": BASE_NAME, "bytes": BASE_SIZE, "sha256": BASE_SHA256, "modified": False},
        "output": {"file": output.name, "bytes": output.stat().st_size, "sha256": sha256(output)},
        "package": "com.ftrakademi.preview3",
        "signer_cert_sha256": signing["certificate_sha256"],
        "signer_count": signing["signer_count"],
        "v1_signature": "PASS" if signing["v1"] else "FAIL",
        "v2_signature": "PASS" if signing["v2"] else "FAIL",
        "zip_alignment": "PASS",
        "zip_integrity": "PASS",
        "duplicate_zip_entries": 0,
        "render_mode": "static-layered-atlas",
        "runtime_webgl": False,
        "runtime_glb": False,
        "continuous_render_loop": False,
        "host_bootstrap": "PASS",
        "module_android_bootstrap": "PASS",
        "changed_existing_payload": changed_existing,
        "added_payload_count": len(added),
        "removed_existing_payload": removed_existing,
        "protected_scope": {
            "all_other_existing_entries_match_by_size_and_crc32": True,
            "lessons_quizzes_movement_program_favorites_notes_auth_supabase_notifications_ftr_ai_untouched": True,
        },
        "physical_phone_qa": "PENDING_USER_RETEST",
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
