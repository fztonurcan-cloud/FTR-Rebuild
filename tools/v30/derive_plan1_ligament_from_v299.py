#!/usr/bin/env python3
"""Derive Plan 1 from the physically verified v29.9 static-atlas artifact.

This is deliberately NOT a renderer. It copies the exact baseline artifact,
changes only ligament-front.png pixels selected by the existing invisible
ligament-id.png, and adds Plan 1 policy flags to atlas-map.json.

The invisible ID map and every structure identity/anchor remain byte/data
identical to the baseline. Any other payload change aborts.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image

BASELINE_ARTIFACT_ID = 9872460705
BASELINE_ARTIFACT_DIGEST = "sha256:48e48fdd5c22428dc73ed7a9df758d60f85b79ca1d15bd2f20539122a4abb235"
EXPECTED_BASELINE_LIGAMENT_ID_SHA256 = "171d2bd119d3e08530d5c6bad77c6a5b6cf66283fdf5455f01a9cb61fcc75eb7"
FRONT_REL = Path("dist/atlas/ligament-front.png")
ID_REL = Path("dist/atlas/ligament-id.png")
MAP_REL = Path("dist/data/atlas-map.json")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def tree_hashes(root: Path) -> dict[str, str]:
    return {
        path.relative_to(root).as_posix(): sha256(path)
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def normalized_ligament(data: dict) -> dict:
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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline", type=Path, required=True, help="Extracted verified Run #68 artifact root")
    parser.add_argument("--output", type=Path, required=True, help="New derived artifact root; must not exist")
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    baseline = args.baseline.resolve()
    output = args.output.resolve()
    report = args.report.resolve()
    if not baseline.is_dir():
        raise SystemExit(f"Baseline artifact directory missing: {baseline}")
    if output.exists():
        raise SystemExit(f"Refusing to overwrite derived artifact directory: {output}")

    for rel in (FRONT_REL, ID_REL, MAP_REL):
        if not (baseline / rel).is_file():
            raise SystemExit(f"Baseline artifact missing {rel}")

    baseline_id_sha = sha256(baseline / ID_REL)
    if baseline_id_sha != EXPECTED_BASELINE_LIGAMENT_ID_SHA256:
        raise SystemExit(f"Refusing unexpected v29.9 ligament ID map: {baseline_id_sha}")

    baseline_data = json.loads((baseline / MAP_REL).read_text(encoding="utf-8"))
    if baseline_data.get("render_mode") != "static-layered-atlas":
        raise SystemExit("Baseline is not the locked static layered atlas")
    baseline_contract = normalized_ligament(baseline_data)
    if baseline_contract["structure_count"] != 292:
        raise SystemExit(f"Unexpected baseline ligament structure count: {baseline_contract['structure_count']}")

    before = tree_hashes(baseline)
    shutil.copytree(baseline, output)

    front_path = output / FRONT_REL
    id_path = output / ID_REL
    map_path = output / MAP_REL

    beauty = Image.open(front_path).convert("RGB")
    ids = Image.open(id_path).convert("RGB")
    if beauty.size != ids.size:
        raise SystemExit(f"Beauty/ID dimensions differ: {beauty.size} vs {ids.size}")

    ligament_rgbs = {
        tuple(int(channel) for channel in row["rgb"])
        for row in baseline_contract["structures"]
    }
    if not ligament_rgbs:
        raise SystemExit("No ligament RGB IDs in baseline atlas map")

    beauty_px = beauty.load()
    id_px = ids.load()
    width, height = beauty.size
    changed = 0
    untouched_checked = 0

    for y in range(height):
        for x in range(width):
            if id_px[x, y] not in ligament_rgbs:
                untouched_checked += 1
                continue
            r, g, b = beauty_px[x, y]
            luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
            beauty_px[x, y] = (
                max(0, min(255, round(178 + 72 * luminance))),
                max(0, min(255, round(22 + 28 * luminance))),
                max(0, min(255, round(30 + 34 * luminance))),
            )
            changed += 1

    if changed < 100:
        raise SystemExit(f"Recolor touched too few ligament pixels: {changed}")
    beauty.save(front_path, optimize=True)

    derived_data = json.loads(map_path.read_text(encoding="utf-8"))
    policy = derived_data.setdefault("policy", {})
    policy["ligament_high_visibility_red"] = True
    policy["ligament_skeleton_reference_preserved"] = True
    policy["ligament_id_map_unchanged_by_recolor"] = True
    policy["plan1_derived_from_physically_verified_v29_9"] = True
    map_path.write_text(json.dumps(derived_data, ensure_ascii=False, indent=2), encoding="utf-8")

    if sha256(id_path) != baseline_id_sha:
        raise SystemExit("Derived artifact changed ligament-id.png")
    if (baseline / ID_REL).read_bytes() != id_path.read_bytes():
        raise SystemExit("Derived artifact ligament ID bytes differ from baseline")

    derived_contract = normalized_ligament(json.loads(map_path.read_text(encoding="utf-8")))
    if derived_contract != baseline_contract:
        raise SystemExit("Derived artifact changed ligament structure IDs/names/anchors")

    after = tree_hashes(output)
    changed_files = sorted(path for path in before if after.get(path) != before[path])
    added_files = sorted(path for path in after if path not in before)
    removed_files = sorted(path for path in before if path not in after)
    expected_changed = {FRONT_REL.as_posix(), MAP_REL.as_posix()}
    if set(changed_files) != expected_changed or added_files or removed_files:
        raise SystemExit(
            f"Derived artifact scope violation: changed={changed_files}, added={added_files}, removed={removed_files}"
        )

    front_sha = sha256(front_path)
    baseline_front_sha = before[FRONT_REL.as_posix()]
    if front_sha == baseline_front_sha:
        raise SystemExit("Ligament beauty layer did not change")

    payload = {
        "status": "PLAN1_DERIVED_ARTIFACT_QA_PASS",
        "baseline_artifact_id": BASELINE_ARTIFACT_ID,
        "baseline_artifact_digest": BASELINE_ARTIFACT_DIGEST,
        "baseline_ligament_id_sha256": baseline_id_sha,
        "derived_ligament_id_sha256": sha256(id_path),
        "ligament_id_byte_identical": True,
        "ligament_structure_contract_unchanged": True,
        "structure_count": baseline_contract["structure_count"],
        "baseline_ligament_front_sha256": baseline_front_sha,
        "derived_ligament_front_sha256": front_sha,
        "recolored_ligament_pixels": changed,
        "non_ligament_pixels_not_selected": untouched_checked,
        "changed_files": changed_files,
        "added_files": added_files,
        "removed_files": removed_files,
        "render_mode": derived_data.get("render_mode"),
        "policy": {key: policy.get(key) for key in [
            "webgl", "runtime_3d_models", "continuous_render_loop",
            "ligament_high_visibility_red", "ligament_skeleton_reference_preserved",
            "ligament_id_map_unchanged_by_recolor", "plan1_derived_from_physically_verified_v29_9",
        ]},
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
