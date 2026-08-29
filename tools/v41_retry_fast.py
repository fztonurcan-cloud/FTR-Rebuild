#!/usr/bin/env python3
import base64, json, os, re, hashlib, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.parse import urljoin, quote
import requests

ROOT=Path('/tmp/ftr-v41-fast-retry'); ROOT.mkdir(parents=True, exist_ok=True)
rows=json.loads(base64.b64decode(Path('tools/v41-fetch/unresolved66.b64').read_text()).decode())
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/142 Safari/537.36'

def kind(d):
    if d.startswith(b'\x89PNG\r\n\x1a\n'): return 'png'
    if d.startswith(b'\xff\xd8\xff'): return 'jpg'
    if d.startswith((b'GIF87a',b'GIF89a')): return 'gif'
    if len(d)>12 and d[:4]==b'RIFF' and d[8:12]==b'WEBP': return 'webp'
    if b'<svg' in d[:1024].lower(): return 'svg'

def save(row,d,method,final,ct):
    p=ROOT/row['local_name']; p.write_bytes(d)
    return {**row,'state':'ok','method':method,'final_url':final,'content_type':ct,'bytes':len(d),'sha256':hashlib.sha256(d).hexdigest(),'kind':kind(d)}

def req(s,u,ref=None,accept='image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',timeout=12):
    h={'User-Agent':UA,'Accept':accept,'Accept-Language':'tr-TR,tr;q=0.9,en;q=0.6','Cache-Control':'no-cache'}
    if ref: h['Referer']=ref
    r=s.get(u,headers=h,timeout=timeout,allow_redirects=True)
    return r

def wayback(row, urls):
    s=requests.Session()
    for original in urls:
        api='https://web.archive.org/cdx/search/cdx?url='+quote(original,safe='')+'&output=json&fl=timestamp,original,mimetype,statuscode,digest&filter=statuscode:200&collapse=digest&limit=20'
        try:
            r=req(s,api,accept='application/json,*/*',timeout=14)
            js=r.json()
            if not isinstance(js,list) or len(js)<2: continue
            # newest first; exact URL only
            for rec in reversed(js[1:]):
                ts,orig=rec[0],rec[1]
                au=f'https://web.archive.org/web/{ts}id_/{orig}'
                try:
                    rr=req(s,au,ref='https://web.archive.org/',timeout=18)
                    d=rr.content; k=kind(d)
                    if rr.status_code==200 and k:
                        return save(row,d,'wayback-exact',rr.url,rr.headers.get('content-type',''))
                except Exception: pass
        except Exception: pass
    return None

def one(row):
    u=row['url']; errs=[]; s=requests.Session(); candidates=[]; pages=[]
    if 'i.resimyukle.xyz/' in u:
        fn=u.rsplit('/',1)[-1]; token=fn.rsplit('.',1)[0]; ext='.'+fn.rsplit('.',1)[1] if '.' in fn else ''
        pages=[f'https://resimyukle.xyz/i/{token}',f'https://resimyukle.xyz/resim/{token}',f'http://resimyukle.xyz/i/{token}',f'http://resimyukle.xyz/resim/{token}']
        candidates=[u,u.replace('https://','http://',1)]
        # Some historic links used another image extension while the share token stayed stable.
        for e in ['.png','.jpg','.jpeg','.webp']:
            candidates += [f'https://i.resimyukle.xyz/{token}{e}',f'http://i.resimyukle.xyz/{token}{e}']
    elif 'hizliresim.com/' in u:
        pages=[u]; token=u.rstrip('/').rsplit('/',1)[-1]
        candidates=[f'https://i.hizliresim.com/{token}.png',f'https://i.hizliresim.com/{token}.jpg',f'https://i.hizliresim.com/{token}.jpeg']
    else:
        candidates=[u,u.replace('http://','https://',1)]
    # Load share pages first to get cookies and discover canonical og:image.
    for page in pages:
        try:
            r=req(s,page,accept='text/html,application/xhtml+xml,*/*;q=0.8',timeout=10)
            text=r.text
            for pat in [r'<meta[^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\'][^>]+content=["\']([^"\']+)',r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\']']:
                for x in re.findall(pat,text,re.I): candidates.insert(0,urljoin(r.url,x))
        except Exception as e: errs.append(f'page:{page}:{type(e).__name__}:{e}')
    seen=set(); cand2=[]
    for x in candidates:
        if x not in seen: seen.add(x); cand2.append(x)
    referers=pages[:2] or [u.rsplit('/',1)[0]+'/']
    for cu in cand2:
        for ref in referers[:2]:
            try:
                r=req(s,cu,ref=ref,timeout=12); d=r.content; k=kind(d)
                if r.status_code==200 and k: return save(row,d,'direct-fast',r.url,r.headers.get('content-type',''))
                errs.append(f'{r.status_code}:{r.headers.get("content-type","")}:{len(d)}:{cu}')
            except Exception as e: errs.append(f'{cu}:{type(e).__name__}:{e}')
    wb=wayback(row,[u]+cand2[:8])
    if wb: return wb
    return {**row,'state':'unresolved','detail':' | '.join(errs)[-5000:]}

out=[]
with ThreadPoolExecutor(max_workers=12) as ex:
    futs={ex.submit(one,r):r for r in rows}
    for i,f in enumerate(as_completed(futs),1):
        try: rec=f.result()
        except Exception as e: rec={**futs[f],'state':'worker-error','detail':repr(e)}
        out.append(rec); print(i,len(rows),rec['state'],rec['url'],flush=True)
out.sort(key=lambda r:(r['source_json'],r['url']))
(ROOT/'status.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
(ROOT/'summary.json').write_text(json.dumps({'total':len(out),'ok':sum(x['state']=='ok' for x in out),'unresolved':sum(x['state']!='ok' for x in out),'methods':{m:sum(x.get('method')==m for x in out) for m in ['direct-fast','wayback-exact']}},indent=2))
print((ROOT/'summary.json').read_text())
