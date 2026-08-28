#!/usr/bin/env python3
from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE_PATH = ROOT / "tools/play_policy_gate.py"
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"
LEGAL = ROOT / "supabase/functions/legal-pages/index.ts"


def load_gate():
    spec = importlib.util.spec_from_file_location("play_policy_gate", GATE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load play_policy_gate.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_gate(module, manifest: Path, legal: Path) -> tuple[int, dict]:
    old_manifest = module.MANIFEST
    old_legal = module.LEGAL
    module.MANIFEST = manifest
    module.LEGAL = legal
    out = io.StringIO()
    try:
        with contextlib.redirect_stdout(out):
            code = module.main()
    finally:
        module.MANIFEST = old_manifest
        module.LEGAL = old_legal
    return code, json.loads(out.getvalue())


def main() -> int:
    module = load_gate()
    results: dict[str, bool] = {}

    clean_code, clean = run_gate(module, MANIFEST, LEGAL)
    results["clean_source_passes"] = clean_code == 0 and clean.get("ok") is True

    with tempfile.TemporaryDirectory(prefix="ftr-play-policy-") as tmp:
        tmp_path = Path(tmp)
        manifest_copy = tmp_path / "AndroidManifest.xml"
        legal_copy = tmp_path / "index.ts"
        shutil.copy2(MANIFEST, manifest_copy)
        shutil.copy2(LEGAL, legal_copy)

        manifest_text = manifest_copy.read_text(encoding="utf-8")
        manifest_text = manifest_text.replace(
            "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">",
            "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">\n"
            "    <uses-permission android:name=\"android.permission.CAMERA\" />",
            1,
        )
        manifest_copy.write_text(manifest_text, encoding="utf-8")
        camera_code, camera = run_gate(module, manifest_copy, legal_copy)
        results["camera_permission_fails"] = (
            camera_code == 2
            and "unexpected_sensitive_android_permission" in camera.get("errors", [])
            and "android_permission_surface_changed" in camera.get("errors", [])
        )

        shutil.copy2(MANIFEST, manifest_copy)
        legal_text = legal_copy.read_text(encoding="utf-8")
        legal_text = legal_text.replace("/functions/v1/account-deletion", "/removed-account-deletion", 2)
        legal_copy.write_text(legal_text, encoding="utf-8")
        deletion_code, deletion = run_gate(module, manifest_copy, legal_copy)
        results["missing_external_delete_link_fails"] = (
            deletion_code == 2 and "external_account_deletion_link" in deletion.get("errors", [])
        )

    ok = all(results.values())
    print(json.dumps({"ok": ok, "checks": results}, ensure_ascii=False, indent=2))
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
