#!/usr/bin/env python3
"""Fail-closed preflight for FTR Akademi v30 three-plan release inputs.

This does not build or modify an APK. It verifies that release inputs are the
locked/approved inputs before build_v30_three_plan_apk.py may be invoked.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from pathlib import Path

BASE_NAME = "FTR-Akademi-v29.9-3D-ANATOMI-STATIC-ATLAS.apk"
BASE_SIZE = 1_137_460_262
BASE_SHA256 = "acbe8ba68cad016d56f4d61e43cfa912e37c65543e5321162d03f69dc220b809"
PLAN1_ARTIFACT_ID = 9891447400
PLAN1_ARTIFACT_DIGEST = "sha256:8cb6fa86d6cc5cae3a4ee1e81d57a163ca85acc3384bdf9e3a0803f89b99c76d"
PLAN1_FRONT_SHA256 = "f6d50400ddbdd31805a82c5b020040ca3c5fcc864fe83be32fa65c81f6ad2028"
PLAN1_ID_SHA256 = "171d2bd119d3e08530d5c6bad77c6a5b6cf66283fdf5455f01a9cb61fcc75eb7"
PLAN1_STRUCTURE_COUNT = 292
BRAND_EXPECTED_DIMS = (112, 112)

CLINICAL_REQUIRED = (
    "index.html",
    "style.css",
    "evidence-enhancer.css",
    "data.js",
    "evidence-overrides.js",
    "turkish-evidence.js",
    "scoring-evidence.js",
    "app.js",
    "visual-enhancer.js",
    "detail-evidence-enhancer.js",
    "RESEARCH-MANIFEST.md",
)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise SystemExit(f"Exact brand asset is not a valid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def normalized_ligament(data: dict) -> dict:
    system = (data.get("systems") or {}).get("ligament") or {}
    rows = system.get("structures") or []
    return {
        "count": int(system.get("structure_count", len(rows))),
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
            for row in rows
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", type=Path, required=True, help="Exact phone-verified v29.9 APK")
    parser.add_argument("--plan1-artifact", type=Path, required=True, help="Extracted locked v29.9-derived Plan 1 artifact")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    base = args.base.resolve()
    repo = args.repo.resolve()
    plan1 = args.plan1_artifact.resolve()

    if not base.is_file() or base.name != BASE_NAME:
        raise SystemExit("RELEASE BLOCKED: exact v29.9 base file is missing/wrong")
    if base.stat().st_size != BASE_SIZE or sha256(base) != BASE_SHA256:
        raise SystemExit("RELEASE BLOCKED: v29.9 base size/SHA mismatch")

    lock_path = repo / "tools" / "v30" / "PLAN1-ARTIFACT-LOCK.json"
    lock = json.loads(lock_path.read_text(encoding="utf-8"))
    expected_lock = {
        "artifact_id": PLAN1_ARTIFACT_ID,
        "artifact_digest": PLAN1_ARTIFACT_DIGEST,
        "derived_ligament_front_sha256": PLAN1_FRONT_SHA256,
        "ligament_id_sha256": PLAN1_ID_SHA256,
        "ligament_structure_count": PLAN1_STRUCTURE_COUNT,
    }
    for key, expected in expected_lock.items():
        if lock.get(key) != expected:
            raise SystemExit(f"RELEASE BLOCKED: Plan 1 lock mismatch at {key}: {lock.get(key)!r}")
    if lock.get("ligament_id_byte_identical_to_v29_9") is not True:
        raise SystemExit("RELEASE BLOCKED: Plan 1 ID-map lock is not byte-identical")
    if lock.get("status") != "PLAN1_DERIVED_ARTIFACT_QA_PASS":
        raise SystemExit("RELEASE BLOCKED: Plan 1 lock status is not PASS")

    front = plan1 / "dist" / "atlas" / "ligament-front.png"
    ids = plan1 / "dist" / "atlas" / "ligament-id.png"
    atlas_map = plan1 / "dist" / "data" / "atlas-map.json"
    for path in (front, ids, atlas_map):
        if not path.is_file():
            raise SystemExit(f"RELEASE BLOCKED: Plan 1 artifact missing {path}")
    if sha256(front) != PLAN1_FRONT_SHA256:
        raise SystemExit("RELEASE BLOCKED: Plan 1 red ligament beauty SHA mismatch")
    if sha256(ids) != PLAN1_ID_SHA256:
        raise SystemExit("RELEASE BLOCKED: Plan 1 invisible ID-map SHA mismatch")
    atlas = json.loads(atlas_map.read_text(encoding="utf-8"))
    ligament = normalized_ligament(atlas)
    if ligament["count"] != PLAN1_STRUCTURE_COUNT:
        raise SystemExit("RELEASE BLOCKED: Plan 1 ligament structure count mismatch")
    policy = atlas.get("policy") or {}
    for flag in (
        "ligament_high_visibility_red",
        "ligament_skeleton_reference_preserved",
        "ligament_id_map_unchanged_by_recolor",
        "plan1_derived_from_physically_verified_v29_9",
    ):
        if policy.get(flag) is not True:
            raise SystemExit(f"RELEASE BLOCKED: Plan 1 required policy missing: {flag}")
    if atlas.get("render_mode") != "static-layered-atlas":
        raise SystemExit("RELEASE BLOCKED: Plan 1 render mode changed")
    if policy.get("webgl") is not False or policy.get("runtime_3d_models") is not False or policy.get("continuous_render_loop") is not False:
        raise SystemExit("RELEASE BLOCKED: Plan 1 static-runtime policy regressed")

    clinical = repo / "tools" / "clinical-scales"
    missing = [name for name in CLINICAL_REQUIRED if not (clinical / name).is_file()]
    if missing:
        raise SystemExit(f"RELEASE BLOCKED: Clinical Scales payload incomplete: {missing}")
    html = (clinical / "index.html").read_text(encoding="utf-8")
    required_refs = (
        "./evidence-enhancer.css",
        "./data.js",
        "./evidence-overrides.js",
        "./turkish-evidence.js",
        "./scoring-evidence.js",
        "./app.js",
        "./visual-enhancer.js",
        "./detail-evidence-enhancer.js",
        "../brand/ftr-logo-exact.png",
    )
    for ref in required_refs:
        if ref not in html:
            raise SystemExit(f"RELEASE BLOCKED: Clinical Scales index missing {ref}")

    brand = repo / "tools" / "brand" / "ftr-logo-exact.png"
    brand_lock = repo / "tools" / "brand" / "ftr-logo-exact.sha256"
    if not brand.is_file() or not brand_lock.is_file():
        raise SystemExit("RELEASE BLOCKED: exact Plan 3 brand PNG/SHA lock is still missing")
    expected_brand_sha = brand_lock.read_text(encoding="utf-8").strip().lower()
    if len(expected_brand_sha) != 64 or any(c not in "0123456789abcdef" for c in expected_brand_sha):
        raise SystemExit("RELEASE BLOCKED: exact Plan 3 brand SHA lock is malformed")
    actual_brand_sha = sha256(brand)
    if actual_brand_sha != expected_brand_sha:
        raise SystemExit("RELEASE BLOCKED: exact Plan 3 brand SHA mismatch")
    dims = png_dimensions(brand)
    if dims != BRAND_EXPECTED_DIMS:
        raise SystemExit(f"RELEASE BLOCKED: exact Plan 3 brand dimensions changed: {dims}")

    result = {
        "status": "V30_THREE_PLAN_RELEASE_INPUTS_PASS",
        "base": {"name": base.name, "bytes": base.stat().st_size, "sha256": BASE_SHA256},
        "plan1": {
            "artifact_id": PLAN1_ARTIFACT_ID,
            "artifact_digest": PLAN1_ARTIFACT_DIGEST,
            "ligament_front_sha256": PLAN1_FRONT_SHA256,
            "ligament_id_sha256": PLAN1_ID_SHA256,
            "structure_count": PLAN1_STRUCTURE_COUNT,
        },
        "plan2": {"required_files": list(CLINICAL_REQUIRED), "count": len(CLINICAL_REQUIRED)},
        "plan3": {"brand_sha256": actual_brand_sha, "dimensions": list(dims)},
        "phone_qa_required": True,
        "final_locked": False,
    }
    if args.report:
        report = args.report.resolve()
        report.parent.mkdir(parents=True, exist_ok=True)
        if report.exists():
            raise SystemExit(f"Refusing to overwrite preflight report: {report}")
        report.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
