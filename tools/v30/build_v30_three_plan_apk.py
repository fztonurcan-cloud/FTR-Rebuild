#!/usr/bin/env python3
"""Fail-closed FTR Akademi v30 three-plan APK builder.

This builder is intentionally based on the physically verified v29.9 APK rather
than repackaging unrelated application content. It permits exactly the three
user-approved plan surfaces:

1. replace only the visible ligament beauty atlas while proving the invisible
   ligament ID map and ligament structure contract are unchanged;
2. add the offline Clinical Scales module;
3. add the exact hash-locked approved FTR brand asset and narrow host bridge.

Any unrelated existing APK payload change aborts the build.
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

BASE_NAME = "FTR-Akademi-v29.9-3D-ANATOMI-STATIC-ATLAS.apk"
BASE_SIZE = 1_137_460_262
BASE_SHA256 = "acbe8ba68cad016d56f4d61e43cfa912e37c65543e5321162d03f69dc220b809"
EXPECTED_CERT_SHA256 = "8771cb32093de52d180d08270909fa5796850900bf7eecaf2b3181873c488be2"
HOST_INDEX = "assets/app/index.html"
LIGAMENT_FRONT = "assets/app/anatomy3d/atlas/ligament-front.png"
LIGAMENT_ID = "assets/app/anatomy3d/atlas/ligament-id.png"
BASE_ATLAS_MAP = "assets/app/anatomy3d/data/atlas-map.json"
CLINICAL_PREFIX = "assets/app/clinical-scales/"
BRAND_RUNTIME = "assets/app/brand/ftr-logo-exact.png"
HOST_CSS = "assets/app/v30-three-plan.css"
HOST_JS = "assets/app/v30-three-plan.js"
VERSION = "v30-three-plan-premium"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


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


def signature_entries(names: list[str]) -> list[str]:
    result: list[str] = []
    for name in names:
        upper = name.upper()
        if upper == "META-INF/MANIFEST.MF" or re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", upper):
            result.append(name)
    return result


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


def source_roots() -> tuple[Path, Path, Path]:
    repo = Path(__file__).resolve().parents[2]
    clinical = repo / "tools" / "clinical-scales"
    brand = repo / "tools" / "brand"
    integration = repo / "tools" / "v30" / "integration"
    return clinical, brand, integration


def validate_exact_brand(brand_root: Path) -> tuple[Path, str]:
    image = brand_root / "ftr-logo-exact.png"
    lock = brand_root / "ftr-logo-exact.sha256"
    if not image.is_file():
        raise SystemExit(
            "RELEASE BLOCKED: exact Plan 3 brand asset is missing. "
            "Do not substitute an AI regeneration or approximation."
        )
    if not lock.is_file():
        raise SystemExit("RELEASE BLOCKED: exact Plan 3 brand SHA-256 lock is missing")
    expected = lock.read_text(encoding="utf-8").strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise SystemExit("RELEASE BLOCKED: exact brand SHA-256 lock is malformed")
    actual = sha256(image)
    if actual != expected:
        raise SystemExit(f"RELEASE BLOCKED: exact brand SHA-256 mismatch: {actual}")
    if image.stat().st_size < 10_000:
        raise SystemExit("RELEASE BLOCKED: exact brand PNG is implausibly small")
    return image, actual


def validate_clinical(clinical_root: Path) -> list[Path]:
    required = [
        "index.html", "style.css", "data.js", "evidence-overrides.js",
        "turkish-evidence.js", "app.js", "visual-enhancer.js", "RESEARCH-MANIFEST.md",
    ]
    missing = [name for name in required if not (clinical_root / name).is_file()]
    if missing:
        raise SystemExit(f"Clinical Scales module incomplete: {missing}")

    index = (clinical_root / "index.html").read_text(encoding="utf-8")
    order = ["./data.js", "./evidence-overrides.js", "./turkish-evidence.js", "./app.js", "./visual-enhancer.js"]
    positions = []
    for item in order:
        if item not in index:
            raise SystemExit(f"Clinical Scales script missing from index: {item}")
        positions.append(index.index(item))
    if positions != sorted(positions):
        raise SystemExit("Clinical Scales script order is unsafe")
    if "../brand/ftr-logo-exact.png" not in index:
        raise SystemExit("Clinical Scales is not wired to the exact Plan 3 brand asset")

    js_text = "\n".join((clinical_root / name).read_text(encoding="utf-8") for name in required if name.endswith(".js"))
    forbidden = ["XMLHttpRequest", "WebSocket", "navigator.geolocation", "navigator.mediaDevices"]
    if any(token in js_text for token in forbidden) or re.search(r"\bfetch\s*\(", js_text):
        raise SystemExit("Clinical Scales violates offline runtime contract")
    for patient_identity in ["patientName", "hastaAdi", "tcKimlik", "TCKN", "emailAddress"]:
        if patient_identity in js_text:
            raise SystemExit(f"Clinical Scales unexpectedly collects patient identity: {patient_identity}")

    return sorted(path for path in clinical_root.iterdir() if path.is_file())


def normalized_ligament_contract(data: dict) -> dict:
    system = (data.get("systems") or {}).get("ligament") or {}
    structures = system.get("structures") or []
    return {
        "structure_count": int(system.get("structure_count", len(structures))),
        "structures": [
            {
                "id": row.get("id"),
                "rgb": row.get("rgb"),
                "name": row.get("name"),
                "raw": row.get("raw"),
                "key": row.get("key"),
                "object_type": row.get("object_type"),
                "anchor": row.get("anchor"),
            }
            for row in structures
        ],
    }


def validate_plan1_artifact(artifact_root: Path, base_archive: zipfile.ZipFile) -> tuple[Path, dict[str, object]]:
    dist = artifact_root / "dist"
    front = dist / "atlas" / "ligament-front.png"
    ids = dist / "atlas" / "ligament-id.png"
    atlas_path = dist / "data" / "atlas-map.json"
    for path in [front, ids, atlas_path]:
        if not path.is_file():
            raise SystemExit(f"Plan 1 artifact missing: {path}")

    data = json.loads(atlas_path.read_text(encoding="utf-8"))
    policy = data.get("policy") or {}
    expected_flags = [
        "ligament_high_visibility_red",
        "ligament_skeleton_reference_preserved",
        "ligament_id_map_unchanged_by_recolor",
    ]
    for flag in expected_flags:
        if policy.get(flag) is not True:
            raise SystemExit(f"Plan 1 artifact missing policy flag: {flag}")
    if data.get("render_mode") != "static-layered-atlas":
        raise SystemExit("Plan 1 artifact is not the locked static-layered-atlas architecture")
    if policy.get("webgl") is not False or policy.get("runtime_3d_models") is not False or policy.get("continuous_render_loop") is not False:
        raise SystemExit("Plan 1 artifact regressed the static performance contract")

    base_id = base_archive.read(LIGAMENT_ID)
    artifact_id = ids.read_bytes()
    if sha256_bytes(base_id) != sha256_bytes(artifact_id):
        raise SystemExit("PLAN 1 BLOCKED: ligament invisible ID map differs from physically verified v29.9")

    base_data = json.loads(base_archive.read(BASE_ATLAS_MAP).decode("utf-8"))
    if normalized_ligament_contract(base_data) != normalized_ligament_contract(data):
        raise SystemExit("PLAN 1 BLOCKED: ligament structure IDs/names/anchors changed")

    if front.stat().st_size < 10_000:
        raise SystemExit("PLAN 1 BLOCKED: red ligament beauty atlas is implausibly small")

    return front, {
        "ligament_front_sha256": sha256(front),
        "ligament_id_sha256": sha256(ids),
        "ligament_id_unchanged": True,
        "ligament_structure_contract_unchanged": True,
        "policy_flags": {flag: True for flag in expected_flags},
    }


def inject_host_bootstrap(source: str) -> str:
    if "data-ftr-v30-three-plan" in source:
        raise SystemExit("Host index already contains a v30 three-plan bootstrap")
    if "</head>" not in source or "</body>" not in source:
        raise SystemExit("Host index is missing </head> or </body>")
    css = f'<link rel="stylesheet" href="./v30-three-plan.css" data-ftr-v30-three-plan="{VERSION}">'
    js = f'<script defer src="./v30-three-plan.js" data-ftr-v30-three-plan="{VERSION}"></script>'
    source = source.replace("</head>", f"  {css}\n</head>", 1)
    source = source.replace("</body>", f"  {js}\n</body>", 1)
    return source


def verify_signing(apksigner: Path, output: Path) -> dict[str, object]:
    result = run([str(apksigner.resolve()), "verify", "--verbose", "--print-certs", str(output)], capture=True)
    text = result.stdout or ""

    def scheme(number: int) -> bool:
        match = re.search(rf"Verified using v{number} scheme[^:]*:\s*(true|false)", text, flags=re.I)
        if not match:
            raise SystemExit(f"apksigner output missing explicit v{number} verification")
        return match.group(1).lower() == "true"

    v1, v2 = scheme(1), scheme(2)
    if not v1 or not v2:
        raise SystemExit(f"APK must verify with v1 and v2; v1={v1}, v2={v2}")
    count = re.search(r"Number of signers:\s*(\d+)", text, flags=re.I)
    if not count or int(count.group(1)) != 1:
        raise SystemExit("Expected exactly one APK signer")
    cert = re.search(r"(?:Signer #1\s*|V2 Signer:\s*)certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)", text, flags=re.I)
    if not cert:
        raise SystemExit("apksigner output missing certificate SHA-256")
    cert_sha = re.sub(r"[^0-9A-Fa-f]", "", cert.group(1)).lower()
    if cert_sha != EXPECTED_CERT_SHA256:
        raise SystemExit(f"Wrong APK signing certificate: {cert_sha}")
    return {"v1": v1, "v2": v2, "signer_count": 1, "certificate_sha256": cert_sha}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True, help="Exact physically verified v29.9 APK")
    parser.add_argument("--plan1-artifact", type=Path, required=True, help="Extracted Run #70 anatomy artifact root")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--zipalign", type=Path, required=True)
    parser.add_argument("--apksigner", type=Path, required=True)
    parser.add_argument("--keystore", type=Path, required=True)
    parser.add_argument("--signing-metadata", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    base = args.base.resolve()
    if not base.is_file():
        raise SystemExit(f"Base APK not found: {base}")
    if base.stat().st_size != BASE_SIZE or sha256(base) != BASE_SHA256:
        raise SystemExit("Refusing any base other than the exact physically verified v29.9 APK")
    if args.output.exists():
        raise SystemExit(f"Refusing to overwrite existing output: {args.output}")

    clinical_root, brand_root, integration_root = source_roots()
    brand_image, brand_sha = validate_exact_brand(brand_root)
    clinical_files = validate_clinical(clinical_root)
    host_css_source = integration_root / "v30-three-plan.css"
    host_js_source = integration_root / "v30-three-plan.js"
    for path in [host_css_source, host_js_source, args.zipalign, args.apksigner, args.keystore, args.signing_metadata]:
        if not path.is_file():
            raise SystemExit(f"Required release input missing: {path}")

    with zipfile.ZipFile(base) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise SystemExit("Base v29.9 APK contains duplicate ZIP entries")
        for required in [HOST_INDEX, LIGAMENT_FRONT, LIGAMENT_ID, BASE_ATLAS_MAP]:
            if required not in names:
                raise SystemExit(f"Base v29.9 APK missing required payload: {required}")
        original_index = archive.read(HOST_INDEX).decode("utf-8")
        original_payload = {
            item.filename: (item.file_size, item.CRC)
            for item in archive.infolist()
            if item.filename not in signature_entries(names)
        }
        plan1_front, plan1_report = validate_plan1_artifact(args.plan1_artifact.resolve(), archive)

    alias, password = signing_values(args.signing_metadata)
    output = args.output.resolve()
    report_path = args.report.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="ftr-v30-three-plan-") as temp_name:
        temp = Path(temp_name)
        stage = temp / "stage"
        app_dir = stage / "assets" / "app"
        clinical_stage = app_dir / "clinical-scales"
        brand_stage = app_dir / "brand"
        anatomy_stage = app_dir / "anatomy3d" / "atlas"
        for directory in [app_dir, clinical_stage, brand_stage, anatomy_stage]:
            directory.mkdir(parents=True, exist_ok=True)

        work_apk = temp / "v30-unaligned.apk"
        aligned_apk = temp / "v30-aligned.apk"
        shutil.copyfile(base, work_apk)

        (app_dir / "index.html").write_text(inject_host_bootstrap(original_index), encoding="utf-8")
        shutil.copyfile(host_css_source, app_dir / "v30-three-plan.css")
        shutil.copyfile(host_js_source, app_dir / "v30-three-plan.js")
        shutil.copyfile(plan1_front, anatomy_stage / "ligament-front.png")
        shutil.copyfile(brand_image, brand_stage / "ftr-logo-exact.png")
        for source in clinical_files:
            shutil.copyfile(source, clinical_stage / source.name)

        removals = signature_entries(names) + [HOST_INDEX, LIGAMENT_FRONT]
        run(["zip", "-q", "-d", str(work_apk), *removals])
        run([
            "zip", "-q", "-9", "-D", "-r", str(work_apk),
            HOST_INDEX,
            HOST_CSS,
            HOST_JS,
            LIGAMENT_FRONT,
            CLINICAL_PREFIX.rstrip("/"),
            BRAND_RUNTIME,
        ], cwd=stage)

        run([str(args.zipalign.resolve()), "-p", "-f", "4", str(work_apk), str(aligned_apk)])
        env = os.environ.copy()
        env["FTR_V30_KS_PASS"] = password
        run([
            str(args.apksigner.resolve()), "sign",
            "--ks", str(args.keystore.resolve()),
            "--ks-key-alias", alias,
            "--ks-pass", "env:FTR_V30_KS_PASS",
            "--key-pass", "env:FTR_V30_KS_PASS",
            "--v1-signing-enabled", "true",
            "--v2-signing-enabled", "true",
            "--v3-signing-enabled", "false",
            "--v4-signing-enabled", "false",
            "--out", str(output), str(aligned_apk),
        ], env=env)

    signing = verify_signing(args.apksigner, output)
    run([str(args.zipalign.resolve()), "-c", "-p", "4", str(output)])

    with zipfile.ZipFile(output) as archive:
        output_names = archive.namelist()
        if len(output_names) != len(set(output_names)):
            raise SystemExit("Output APK contains duplicate ZIP entries")
        bad_entry = archive.testzip()
        if bad_entry:
            raise SystemExit(f"Output ZIP integrity failed at: {bad_entry}")
        output_payload = {
            item.filename: (item.file_size, item.CRC)
            for item in archive.infolist()
            if item.filename not in signature_entries(output_names)
        }
        if archive.read(LIGAMENT_ID) != zipfile.ZipFile(base).read(LIGAMENT_ID):
            raise SystemExit("Output unexpectedly changed the ligament invisible ID map")
        if sha256_bytes(archive.read(BRAND_RUNTIME)) != brand_sha:
            raise SystemExit("Output exact brand asset hash changed during packaging")
        host_index = archive.read(HOST_INDEX).decode("utf-8")
        if host_index.count("data-ftr-v30-three-plan") != 2:
            raise SystemExit("v30 host bootstrap missing or duplicated")

    expected_changed = {HOST_INDEX, LIGAMENT_FRONT}
    changed_existing = sorted(
        name for name, old in original_payload.items()
        if name in output_payload and output_payload[name] != old
    )
    removed_existing = sorted(name for name in original_payload if name not in output_payload)
    if set(changed_existing) != expected_changed:
        raise SystemExit(f"OUT-OF-SCOPE existing APK payload changed: {changed_existing}")
    if removed_existing:
        raise SystemExit(f"OUT-OF-SCOPE existing APK payload removed: {removed_existing}")

    expected_added = {HOST_CSS, HOST_JS, BRAND_RUNTIME} | {
        CLINICAL_PREFIX + path.name for path in clinical_files
    }
    actual_added = {name for name in output_payload if name not in original_payload}
    if actual_added != expected_added:
        extra = sorted(actual_added - expected_added)
        missing = sorted(expected_added - actual_added)
        raise SystemExit(f"v30 added payload mismatch; extra={extra}, missing={missing}")

    report = {
        "version": VERSION,
        "status": "BUILD_STATIC_QA_PASS_PHONE_QA_REQUIRED",
        "base": {"file": BASE_NAME, "bytes": BASE_SIZE, "sha256": BASE_SHA256, "modified": False},
        "output": {"file": output.name, "bytes": output.stat().st_size, "sha256": sha256(output)},
        "package_expected": "com.ftrakademi.preview3",
        "signing": signing,
        "three_plan_scope": {
            "changed_existing": changed_existing,
            "removed_existing": removed_existing,
            "added_count": len(actual_added),
            "plan1": plan1_report,
            "plan2": {"clinical_files": sorted(path.name for path in clinical_files), "offline": True, "patient_identity": False},
            "plan3": {"brand_sha256": brand_sha, "hash_locked": True, "logo_is_home": True},
        },
        "physical_phone_qa": "PENDING_USER_RETEST",
        "final_locked": False,
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
