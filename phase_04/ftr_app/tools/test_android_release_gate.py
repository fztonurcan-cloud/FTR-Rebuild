#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / "tools" / "android_release_gate.py"
BASE_ARGS = [
    "--identity-confirmed", "YES",
    "--android-id", "com.mobiroller.mobi743032079412",
    "--play-highest-version-code", "24",
    "--next-version-code", "25",
    "--version-name", "4.0.0",
    "--expect-legacy-id", "com.mobiroller.mobi743032079412",
]


def run_gate(root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(GATE), "--root", str(root), *BASE_ARGS],
        text=True,
        capture_output=True,
        check=False,
    )


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def copy_fixture() -> tuple[tempfile.TemporaryDirectory[str], Path]:
    td = tempfile.TemporaryDirectory(prefix="ftr_gate_")
    dst = Path(td.name) / "app"
    shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns("build", "dist", ".dart_tool"))
    return td, dst


def main() -> int:
    clean = run_gate(ROOT)
    require(clean.returncode == 0, f"clean source should pass:\n{clean.stdout}\n{clean.stderr}")

    td1, app1 = copy_fixture()
    try:
        gradle = app1 / "android" / "app" / "build.gradle.kts"
        gradle.write_text(
            gradle.read_text(encoding="utf-8").replace(
                'applicationId = "com.mobiroller.mobi743032079412"',
                'applicationId = "com.example.tampered"',
            ),
            encoding="utf-8",
        )
        tampered_id = run_gate(app1)
        require(tampered_id.returncode != 0, "tampered applicationId must fail")
    finally:
        td1.cleanup()

    td2, app2 = copy_fixture()
    try:
        pubspec = app2 / "pubspec.yaml"
        pubspec.write_text(
            pubspec.read_text(encoding="utf-8").replace("version: 4.0.0+25", "version: 4.0.0+24"),
            encoding="utf-8",
        )
        tampered_version = run_gate(app2)
        require(tampered_version.returncode != 0, "tampered pubspec version must fail")
    finally:
        td2.cleanup()

    print(json.dumps({
        "ok": True,
        "clean_source": "PASS",
        "tampered_application_id": "FAIL_AS_EXPECTED",
        "tampered_pubspec_version": "FAIL_AS_EXPECTED",
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
