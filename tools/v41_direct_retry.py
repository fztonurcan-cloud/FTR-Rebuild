#!/usr/bin/env python3
import base64,json,re,hashlib
from concurrent.futures import ThreadPoolExecutor,as_completed
from pathlib import Path
from urllib.parse import urljoin
import requests
ROOT=Path('/tmp/ftr-v41-direct-retry');ROOT.mkdir(parents=True,exist_ok=True)
rows=json.loads(base64.b64decode(Path('tools/v41-fetch/unresolved66.b64').read_text()).decode())
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/142 Safari/537.36'
def kind(d):
 if d.startswith(b'\x89PNG\r\n\x1a\n'): return 'png'
 if d.startswith(b'\xff\xd8\xff'): return 'jpg'
 if d.startswith((b'GIF87a',b'GIF89a')): return 'gif'
 if len(d)>12 and d[:4]==b'RIFF' and d[8:12]==b'WEBP': return 'webp'
def one(row):
 s=requests.Session();u=row['url'];c=[];refs=[];errs=[]
 if 'i.resimyukle.xyz/' in u:
  fn=u.rsplit('/',1)[-1];tok=fn.rsplit('.',1)[0]
  pages=[f'https://resimyukle.xyz/i/{tok}',f'https://resimyukle.xyz/resim/{tok}',f'https://resimyukle.xyz/{tok}']
  for pg in pages:
   try:
    r=s.get(pg,headers={'User-Agent':UA},timeout=5,allow_redirects=True);refs.append(r.url)
    for pat in [r'<meta[^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\'][^>]+content=["\']([^"\']+)',r'<img[^>]+src=["\']([^"\']+)["\']']:
     c += [urljoin(r.url,x) for x in re.findall(pat,r.text,re.I)]
   except Exception as e: errs.append('page:'+type(e).__name__)
  c += [u,u.replace('https://','http://',1)]
  for ext in ['png','jpg','jpeg','webp']:
   c += [f'https://i.resimyukle.xyz/{tok}.{ext}',f'http://i.resimyukle.xyz/{tok}.{ext}']
 elif 'hizliresim.com/' in u:
  tok=u.rstrip('/').rsplit('/',1)[-1];refs=[u]
  c=[f'https://i.hizliresim.com/{tok}.png',f'https://i.hizliresim.com/{tok}.jpg']
 else:
  refs=[u.rsplit('/',1)[0]+'/'];c=[u,u.replace('http://','https://',1)]
 seen=set()
 for x in c:
  if x in seen: continue
  seen.add(x)
  for ref in (refs[:2] or [None]):
   try:
    h={'User-Agent':UA,'Accept':'image/avif,image/webp,image/apng,image/*,*/*;q=.8'}
    if ref:h['Referer']=ref
    r=s.get(x,headers=h,timeout=5,allow_redirects=True);d=r.content;k=kind(d)
    if r.status_code==200 and k:
     (ROOT/row['local_name']).write_bytes(d)
     return {**row,'state':'ok','method':'direct-short','final_url':r.url,'kind':k,'bytes':len(d),'sha256':hashlib.sha256(d).hexdigest()}
   except Exception as e: errs.append(type(e).__name__)
 return {**row,'state':'unresolved','detail':','.join(errs[-30:])}
out=[]
with ThreadPoolExecutor(max_workers=32) as ex:
 fs=[ex.submit(one,r) for r in rows]
 for i,f in enumerate(as_completed(fs),1):
  rec=f.result();out.append(rec);print(i,len(rows),rec['state'],rec['url'],flush=True)
(ROOT/'status.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
s={'total':len(out),'ok':sum(x['state']=='ok' for x in out),'unresolved':sum(x['state']!='ok' for x in out)}
(ROOT/'summary.json').write_text(json.dumps(s,indent=2));print(json.dumps(s,indent=2))
