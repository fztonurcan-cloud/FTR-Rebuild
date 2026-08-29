#!/usr/bin/env python3
import csv, hashlib, html, json, os, re, sys, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, unquote
from urllib.request import Request, urlopen

ROOT = Path(os.environ.get('FTR_FETCH_ROOT', '/tmp/ftr-v41-fetch'))
MANIFEST_DIR = Path(os.environ.get('FTR_MANIFEST_DIR', '/tmp/ftr-v41-manifests'))
IMG_DIR = ROOT / 'images'
PDF_DIR = ROOT / 'documents'
ROOT.mkdir(parents=True, exist_ok=True)
IMG_DIR.mkdir(parents=True, exist_ok=True)
PDF_DIR.mkdir(parents=True, exist_ok=True)
UA = 'Mozilla/5.0 (Linux; Android 14; FTR-v41-audit) AppleWebKit/537.36 Chrome/142 Safari/537.36'
MAX_BYTES = 40 * 1024 * 1024


def fetch(url, timeout=20, max_bytes=MAX_BYTES):
    req = Request(url, headers={
        'User-Agent': UA,
        'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.7',
        'Cache-Control': 'no-cache',
    })
    with urlopen(req, timeout=timeout) as r:
        final = r.geturl()
        ctype = (r.headers.get('Content-Type') or '').split(';')[0].strip().lower()
        data = r.read(max_bytes + 1)
        if len(data) > max_bytes:
            raise ValueError('response-too-large')
        return r.status, final, ctype, data


def image_kind(data):
    if data.startswith(b'\xff\xd8\xff'): return 'jpeg'
    if data.startswith(b'\x89PNG\r\n\x1a\n'): return 'png'
    if data.startswith((b'GIF87a', b'GIF89a')): return 'gif'
    if len(data) >= 12 and data[:4] == b'RIFF' and data[8:12] == b'WEBP': return 'webp'
    if data.lstrip().startswith(b'<svg') or (b'<svg' in data[:512].lower()): return 'svg'
    return None


def wayback_exact(url):
    # Exact-URL fallback only. We do not search for similar images.
    api = ('https://web.archive.org/cdx/search/cdx?url=' + quote(url, safe='') +
           '&output=json&fl=timestamp,original,mimetype,statuscode,digest'
           '&filter=statuscode:200&filter=mimetype:image/.*&collapse=digest&limit=10')
    try:
        _, _, _, raw = fetch(api, timeout=25, max_bytes=2 * 1024 * 1024)
        rows = json.loads(raw.decode('utf-8', 'replace'))
        if not isinstance(rows, list) or len(rows) < 2:
            return None
        # Prefer snapshots around 2017-2020 for the legacy corpus, then newest remaining.
        candidates = rows[1:]
        candidates.sort(key=lambda r: (0 if '2017' <= r[0][:4] <= '2020' else 1, r[0]))
        for row in candidates:
            ts, original = row[0], row[1]
            archive = f'https://web.archive.org/web/{ts}id_/{original}'
            try:
                status, final, ctype, data = fetch(archive, timeout=30)
                kind = image_kind(data)
                if kind:
                    return status, final, ctype, data, ts
            except Exception:
                continue
    except Exception:
        pass
    return None


def download_image(row):
    src, local_name, url = row['source_json'], row['local_name'], row['url']
    attempts = []
    urls = [url]
    if url.startswith('http://'):
        urls.append('https://' + url[len('http://'):])
    for candidate in urls:
        try:
            status, final, ctype, data = fetch(candidate)
            kind = image_kind(data)
            attempts.append(f'{candidate} -> {status} {ctype} {len(data)}')
            if kind:
                out = IMG_DIR / local_name
                out.write_bytes(data)
                return {
                    'source_json': src, 'local_name': local_name, 'url': url,
                    'state': 'ok', 'method': 'direct', 'http_status': status,
                    'final_url': final, 'content_type': ctype, 'kind': kind,
                    'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                    'detail': ' | '.join(attempts)
                }
        except Exception as e:
            attempts.append(f'{candidate} -> {type(e).__name__}:{e}')
    # Archive fallback only for the three known fztdulger legacy lesson images.
    if 'fztdulger.com/' in url:
        wb = wayback_exact(url)
        if wb:
            status, final, ctype, data, ts = wb
            kind = image_kind(data)
            out = IMG_DIR / local_name
            out.write_bytes(data)
            return {
                'source_json': src, 'local_name': local_name, 'url': url,
                'state': 'ok', 'method': 'wayback-exact-url', 'http_status': status,
                'final_url': final, 'content_type': ctype, 'kind': kind,
                'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                'detail': f'wayback_timestamp={ts}; ' + ' | '.join(attempts)
            }
    return {
        'source_json': src, 'local_name': local_name, 'url': url,
        'state': 'unresolved', 'method': '', 'http_status': '', 'final_url': '',
        'content_type': '', 'kind': '', 'bytes': 0, 'sha256': '',
        'detail': ' | '.join(attempts)[:2000]
    }


def pdf_candidates(text):
    text = html.unescape(text).replace('\\/', '/')
    found = set()
    patterns = [
        r'https?://[^\s"\'<>]+?\.pdf(?:\?[^\s"\'<>]*)?',
        r'"(?:downloadUri|downloadURL|downloadUrl|contentUrl|assetUri|assetURL|pdfUrl|pdfURL)"\s*:\s*"([^"]+)"',
    ]
    for pat in patterns:
        for m in re.finditer(pat, text, flags=re.I):
            v = m.group(1) if m.lastindex else m.group(0)
            v = unquote(v.replace('\\u0026', '&'))
            if v.startswith('http://') or v.startswith('https://'):
                found.add(v)
    return list(found)[:30]


def audit_adobe(row):
    src, urn, url = row['source_json'], row['urn_id'], row['url']
    result = {
        'source_json': src, 'urn_id': urn, 'url': url, 'state': 'viewer-only',
        'http_status': '', 'final_url': '', 'content_type': '', 'bytes': 0,
        'sha256': '', 'pdf_source_url': '', 'detail': ''
    }
    try:
        status, final, ctype, data = fetch(url, timeout=30, max_bytes=12*1024*1024)
        result.update(http_status=status, final_url=final, content_type=ctype, bytes=len(data))
        if data.startswith(b'%PDF'):
            out = PDF_DIR / f'{urn}.pdf'
            out.write_bytes(data)
            result.update(state='exact-pdf', sha256=hashlib.sha256(data).hexdigest(), pdf_source_url=final)
            return result
        text = data.decode('utf-8', 'replace')
        cands = pdf_candidates(text)
        failures = []
        for cand in cands:
            try:
                s2, f2, c2, d2 = fetch(cand, timeout=30, max_bytes=40*1024*1024)
                if d2.startswith(b'%PDF'):
                    out = PDF_DIR / f'{urn}.pdf'
                    out.write_bytes(d2)
                    result.update(state='exact-pdf', http_status=s2, final_url=f2, content_type=c2,
                                  bytes=len(d2), sha256=hashlib.sha256(d2).hexdigest(), pdf_source_url=cand,
                                  detail=f'candidate_count={len(cands)}')
                    return result
                failures.append(f'{s2}:{c2}:{len(d2)}:{cand[:140]}')
            except Exception as e:
                failures.append(f'{type(e).__name__}:{str(e)[:120]}:{cand[:140]}')
        result['detail'] = f'candidate_count={len(cands)}; ' + ' | '.join(failures[:5])
    except Exception as e:
        result.update(state='unresolved', detail=f'{type(e).__name__}:{e}')
    return result


def read_tsv(path):
    with open(path, newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f, delimiter='\t'))


def write_tsv(path, rows, fields):
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter='\t', extrasaction='ignore')
        w.writeheader(); w.writerows(rows)


def main():
    images = read_tsv(MANIFEST_DIR / 'external_images.tsv')
    adobe = read_tsv(MANIFEST_DIR / 'adobe_links.tsv')
    print(f'Image URLs: {len(images)}; Adobe share URLs: {len(adobe)}', flush=True)

    img_results = []
    with ThreadPoolExecutor(max_workers=32) as ex:
        futs = [ex.submit(download_image, r) for r in images]
        for i, fut in enumerate(as_completed(futs), 1):
            try: img_results.append(fut.result())
            except Exception as e: img_results.append({'state':'worker-error','detail':repr(e)})
            if i % 100 == 0: print(f'images {i}/{len(images)}', flush=True)
    img_results.sort(key=lambda r: (r.get('source_json',''), r.get('url','')))
    img_fields = ['source_json','local_name','url','state','method','http_status','final_url','content_type','kind','bytes','sha256','detail']
    write_tsv(ROOT / 'image_status.tsv', img_results, img_fields)

    adobe_results = []
    with ThreadPoolExecutor(max_workers=12) as ex:
        futs = [ex.submit(audit_adobe, r) for r in adobe]
        for i, fut in enumerate(as_completed(futs), 1):
            try: adobe_results.append(fut.result())
            except Exception as e: adobe_results.append({'state':'worker-error','detail':repr(e)})
            if i % 25 == 0: print(f'adobe {i}/{len(adobe)}', flush=True)
    adobe_results.sort(key=lambda r: (r.get('source_json',''), r.get('url','')))
    adobe_fields = ['source_json','urn_id','url','state','http_status','final_url','content_type','bytes','sha256','pdf_source_url','detail']
    write_tsv(ROOT / 'adobe_status.tsv', adobe_results, adobe_fields)

    summary = {
        'images_total': len(images),
        'images_ok': sum(r.get('state') == 'ok' for r in img_results),
        'images_unresolved': sum(r.get('state') != 'ok' for r in img_results),
        'images_direct': sum(r.get('method') == 'direct' for r in img_results),
        'images_wayback': sum(r.get('method') == 'wayback-exact-url' for r in img_results),
        'adobe_total': len(adobe),
        'adobe_exact_pdf': sum(r.get('state') == 'exact-pdf' for r in adobe_results),
        'adobe_viewer_only': sum(r.get('state') == 'viewer-only' for r in adobe_results),
        'adobe_unresolved': sum(r.get('state') == 'unresolved' for r in adobe_results),
    }
    (ROOT / 'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print(json.dumps(summary, indent=2), flush=True)

if __name__ == '__main__':
    main()
