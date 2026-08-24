#!/usr/bin/env python3
"""Trusted FTR media uploader.

Default mode is dry-run and never contacts Supabase.
Execution requires a server-only service-role key in the environment and must
run only on a trusted maintainer/CI host. The key is never written to disk.

Flow per asset:
  1. Verify local bytes + SHA-256.
  2. Upload to private `content-assets` bucket at immutable canonical path.
  3. Download the just-uploaded object with the service role and verify SHA-256.
  4. Call service_register_media_upload(), which independently confirms the
     Storage object exists, its path is bound to the replacement asset, and the
     expected SHA matches the database record.

This script intentionally does NOT promote assets to public.content_assets.
Promotion is a separate editorial action after production_status='approved'.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

BUCKET = "content-assets"
ALLOWED_MIME = {"image/png", "image/jpeg", "image/webp", "video/mp4"}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def request(url: str, *, method: str, key: str, body: bytes | None = None,
            content_type: str | None = None, extra_headers: dict[str, str] | None = None) -> bytes:
    headers = {
        "Authorization": f"Bearer {key}",
        "apikey": key,
    }
    if content_type:
        headers["Content-Type"] = content_type
    if extra_headers:
        headers.update(extra_headers)
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        payload = exc.read().decode("utf-8", errors="replace")[:1200]
        raise RuntimeError(f"HTTP {exc.code} for {method} {url}: {payload}") from exc


def upload_object(base_url: str, key: str, storage_path: str, file_path: Path, mime: str) -> None:
    encoded = "/".join(urllib.parse.quote(part, safe="") for part in storage_path.split("/"))
    url = f"{base_url}/storage/v1/object/{BUCKET}/{encoded}"
    data = file_path.read_bytes()
    try:
        request(
            url,
            method="POST",
            key=key,
            body=data,
            content_type=mime,
            extra_headers={"x-upsert": "false", "cache-control": "3600"},
        )
    except RuntimeError as exc:
        # Idempotent reruns are allowed only if the existing object later hashes
        # to the exact expected SHA. Do not blindly overwrite immutable paths.
        if "HTTP 400" not in str(exc) and "HTTP 409" not in str(exc):
            raise


def download_object(base_url: str, key: str, storage_path: str) -> bytes:
    encoded = "/".join(urllib.parse.quote(part, safe="") for part in storage_path.split("/"))
    url = f"{base_url}/storage/v1/object/authenticated/{BUCKET}/{encoded}"
    return request(url, method="GET", key=key)


def register_upload(base_url: str, key: str, item: dict[str, object]) -> dict[str, object]:
    url = f"{base_url}/rest/v1/rpc/service_register_media_upload"
    payload = json.dumps({
        "p_replacement_asset_id": item["replacement_asset_id"],
        "p_storage_path": item["storage_path"],
        "p_sha256": item["sha256"],
    }).encode("utf-8")
    raw = request(url, method="POST", key=key, body=payload, content_type="application/json")
    decoded = json.loads(raw.decode("utf-8"))
    if not isinstance(decoded, dict):
        raise RuntimeError("Unexpected registration response")
    return decoded


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--root", default=".", help="Root used to resolve manifest local_path values")
    parser.add_argument("--execute", action="store_true", help="Actually upload after local validation")
    parser.add_argument("--result-json", default=None)
    args = parser.parse_args()

    manifest_path = Path(args.manifest).resolve()
    root = Path(args.root).resolve()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assets = manifest.get("assets", [])
    if not isinstance(assets, list) or not assets:
        raise SystemExit("Manifest contains no assets")

    validated: list[dict[str, object]] = []
    errors: list[str] = []
    for raw_item in assets:
        item = dict(raw_item)
        path = (root / str(item["local_path"])).resolve()
        if not path.is_file():
            errors.append(f"missing: {item['local_path']}")
            continue
        expected = str(item["sha256"]).lower()
        actual = sha256_file(path)
        if actual != expected:
            errors.append(f"sha mismatch: {item['local_path']} expected={expected} actual={actual}")
            continue
        expected_size = int(item.get("size_bytes") or 0)
        if expected_size and path.stat().st_size != expected_size:
            errors.append(f"size mismatch: {item['local_path']}")
            continue
        mime = str(item.get("mime_type") or mimetypes.guess_type(path.name)[0] or "")
        if mime not in ALLOWED_MIME:
            errors.append(f"unsupported mime {mime}: {item['local_path']}")
            continue
        item["_resolved_path"] = str(path)
        item["mime_type"] = mime
        validated.append(item)

    summary: dict[str, object] = {
        "manifest": str(manifest_path),
        "asset_count": len(assets),
        "locally_validated": len(validated),
        "errors": errors,
        "executed": bool(args.execute),
        "registered": [],
    }

    if errors:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 2

    if not args.execute:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 0

    base_url = os.environ.get("SUPABASE_URL", "").rstrip("/")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
    if not base_url or not key:
        raise SystemExit("--execute requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the trusted environment")
    if key.startswith("sb_publishable_"):
        raise SystemExit("Refusing publishable key: trusted upload requires a server-only service-role/secret credential")

    registered: list[dict[str, object]] = []
    for item in validated:
        file_path = Path(str(item.pop("_resolved_path")))
        print(f"uploading {item['replacement_asset_id']} -> {item['storage_path']}")
        upload_object(base_url, key, str(item["storage_path"]), file_path, str(item["mime_type"]))
        downloaded = download_object(base_url, key, str(item["storage_path"]))
        downloaded_sha = hashlib.sha256(downloaded).hexdigest()
        if downloaded_sha != item["sha256"]:
            raise RuntimeError(
                f"remote SHA mismatch for {item['storage_path']}: expected {item['sha256']} got {downloaded_sha}"
            )
        registration = register_upload(base_url, key, item)
        registered.append(registration)

    summary["registered"] = registered
    if args.result_json:
        Path(args.result_json).write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
