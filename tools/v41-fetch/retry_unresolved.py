#!/usr/bin/env python3
import base64, json, os, re, time, hashlib
from pathlib import Path
from urllib.request import Request, build_opener, HTTPCookieProcessor
from http.cookiejar import CookieJar
from urllib.parse import urljoin

ROOT=Path('/tmp/ftr-v41-retry'); ROOT.mkdir(parents=True,exist_ok=True)
rows=json.loads(base64.b64decode(Path('tools/v41-fetch/unresolved66.b64').read_text()).decode())
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/142 Safari/537.36'
opener=build_opener(HTTPCookieProcessor(CookieJar()))

def kind(d):
    if d.startswith(b'\x89PNG\r\n\x1a\n'): return 'png'
    if d.startswith(b'\xff\xd8\xff'): return 'jpg'
    if d.startswith((b'GIF87a',b'GIF89a')): return 'gif'
    if len(d)>12 and d[:4]==b'RIFF' and d[8:12]==b'WEBP': return 'webp'

def get(url, referer=None):
    h={'User-Agent':UA,'Accept':'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8','Accept-Language':'tr-TR,tr;q=0.9,en;q=0.6'}
    if referer: h['Referer']=referer
    r=opener.open(Request(url,headers=h),timeout=30); return r.geturl(),(r.headers.get('Content-Type') or ''),r.read(50*1024*1024)

out=[]
for i,row in enumerate(rows,1):
    u=row['url']; got=None; errs=[]
    candidates=[]
    if 'i.resimyukle.xyz/' in u:
        token=u.rsplit('/',1)[-1]
        candidates=[(u,'https://resimyukle.xyz/'),(u.replace('https://i.resimyukle.xyz/','http://i.resimyukle.xyz/'),'http://resimyukle.xyz/')]
    elif 'hizliresim.com/' in u:
        try:
            final,ct,d=get(u)
            txt=d.decode('utf-8','ignore')
            ms=re.findall(r'(?:og:image|twitter:image)[^>]+content=["\']([^"\']+)',txt,re.I)
            ms+=re.findall(r'content=["\']([^"\']+)["\'][^>]+(?:og:image|twitter:image)',txt,re.I)
            candidates += [(urljoin(final,x),final) for x in ms]
        except Exception as e: errs.append('page:'+repr(e))
    else:
        candidates=[(u,u.rsplit('/',1)[0]+'/'),(u.replace('http://','https://',1),u.rsplit('/',1)[0]+'/')]
    for attempt in range(3):
        for cu,ref in candidates:
            try:
                final,ct,d=get(cu,ref); k=kind(d)
                if k:
                    p=ROOT/row['local_name']; p.write_bytes(d)
                    got={'state':'ok','method':'retry','final_url':final,'content_type':ct,'bytes':len(d),'sha256':hashlib.sha256(d).hexdigest()}; break
                errs.append(f'not-image:{cu}:{ct}:{len(d)}')
            except Exception as e: errs.append(f'{cu}:{type(e).__name__}:{e}')
        if got: break
        time.sleep(4+attempt*5)
    rec={**row,**(got or {'state':'unresolved'}),'detail':' | '.join(errs)[-3000:]}; out.append(rec)
    print(i,len(rows),rec['state'],u,flush=True)
    time.sleep(1.5)
Path('/tmp/ftr-v41-retry/status.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
Path('/tmp/ftr-v41-retry/summary.json').write_text(json.dumps({'total':len(out),'ok':sum(x['state']=='ok' for x in out),'unresolved':sum(x['state']!='ok' for x in out)},indent=2))
