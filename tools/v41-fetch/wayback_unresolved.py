#!/usr/bin/env python3
import base64,json,hashlib,time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
from urllib.parse import quote
from urllib.request import Request,urlopen
OUT=Path('/tmp/ftr-wayback'); OUT.mkdir(parents=True,exist_ok=True)
rows=json.loads(base64.b64decode(Path('tools/v41-fetch/unresolved66.b64').read_text()).decode())
rows=[r for r in rows if 'i.resimyukle.xyz/' in r['url']]
UA='Mozilla/5.0'
def get(u,timeout=25,limit=50*1024*1024):
 req=Request(u,headers={'User-Agent':UA})
 with urlopen(req,timeout=timeout) as x: return x.status,x.geturl(),(x.headers.get('content-type') or ''),x.read(limit+1)
def kind(d):
 if d.startswith(b'\x89PNG\r\n\x1a\n'): return 'png'
 if d.startswith(b'\xff\xd8\xff'): return 'jpg'
 if d.startswith((b'GIF87a',b'GIF89a')): return 'gif'
 if len(d)>12 and d[:4]==b'RIFF' and d[8:12]==b'WEBP': return 'webp'
def one(r):
 u=r['url']; detail=[]
 api='https://web.archive.org/cdx/search/cdx?url='+quote(u,safe='')+'&output=json&fl=timestamp,original,statuscode,mimetype,digest&filter=statuscode:200&collapse=digest&limit=20'
 try:
  _,_,_,raw=get(api,30,2*1024*1024); rows=json.loads(raw.decode('utf8','replace'))
  if isinstance(rows,list) and len(rows)>1:
   for x in reversed(rows[1:]):
    ts,orig=x[0],x[1]; au=f'https://web.archive.org/web/{ts}id_/{orig}'
    try:
     s,f,ct,d=get(au,35); k=kind(d)
     if k:
      p=OUT/r['local_name']; p.write_bytes(d)
      return {**r,'state':'ok','timestamp':ts,'archive_url':f,'bytes':len(d),'sha256':hashlib.sha256(d).hexdigest(),'kind':k}
    except Exception as e: detail.append(type(e).__name__+':'+str(e)[:100])
 except Exception as e: detail.append('cdx:'+type(e).__name__+':'+str(e)[:150])
 return {**r,'state':'miss','detail':' | '.join(detail)[-1000:]}
res=[]
with ThreadPoolExecutor(max_workers=12) as ex:
 futs=[ex.submit(one,r) for r in rows]
 for i,f in enumerate(as_completed(futs),1):
  rr=f.result();res.append(rr);print(i,len(rows),rr['state'],rr['url'],flush=True)
Path('/tmp/ftr-wayback/status.json').write_text(json.dumps(res,ensure_ascii=False,indent=2))
Path('/tmp/ftr-wayback/summary.json').write_text(json.dumps({'total':len(res),'ok':sum(x['state']=='ok' for x in res),'miss':sum(x['state']!='ok' for x in res)},indent=2))
