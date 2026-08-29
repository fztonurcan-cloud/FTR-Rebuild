#!/usr/bin/env python3
import csv, hashlib, html, json, os, re, time
from pathlib import Path
from urllib.parse import quote, urlparse
import requests

MAN=Path('/tmp/ftr-v41-manifests/external_images.tsv')
OUT=Path('/tmp/ftr-v41-recover'); IMG=OUT/'images'; IMG.mkdir(parents=True,exist_ok=True)
S=requests.Session(); S.headers.update({'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/142 Safari/537.36','Accept-Language':'tr-TR,tr;q=0.9,en;q=0.7'})

def kind(b):
    if b.startswith(b'\xff\xd8\xff'): return 'jpg'
    if b.startswith(b'\x89PNG\r\n\x1a\n'): return 'png'
    if b.startswith((b'GIF87a',b'GIF89a')): return 'gif'
    if len(b)>12 and b[:4]==b'RIFF' and b[8:12]==b'WEBP': return 'webp'
    return None

def get(url, referer=None, timeout=25):
    h={'Accept':'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8'}
    if referer: h['Referer']=referer
    r=S.get(url,headers=h,timeout=timeout,allow_redirects=True)
    return r

def wayback(url):
    variants=[url]
    if url.startswith('https://'): variants.append('http://'+url[8:])
    if url.startswith('http://'): variants.append('https://'+url[7:])
    for u in variants:
        api='https://web.archive.org/cdx/search/cdx?url='+quote(u,safe='')+'&output=json&fl=timestamp,original,mimetype,statuscode&filter=statuscode:200&collapse=digest&limit=30'
        try:
            rows=S.get(api,timeout=30).json()
        except Exception: continue
        if not isinstance(rows,list) or len(rows)<2: continue
        for row in reversed(rows[1:]):
            ts,orig=row[0],row[1]
            try:
                r=get(f'https://web.archive.org/web/{ts}id_/{orig}', 'https://web.archive.org/', 30)
                if r.ok and kind(r.content): return r.content, f'wayback:{ts}:{orig}'
            except Exception: pass
    return None

def recover_resimyukle(url):
    p=urlparse(url); base=Path(p.path).name; stem=base.rsplit('.',1)[0]
    page_candidates=[f'https://resimyukle.xyz/{stem}',f'https://resimyukle.xyz/{base}',f'https://www.resimyukle.xyz/{stem}']
    # establish cookies / parse any canonical image URLs
    discovered=[]
    for page in ['https://resimyukle.xyz/']+page_candidates:
        try:
            r=S.get(page,timeout=20,allow_redirects=True)
            if 'text/html' in r.headers.get('content-type',''):
                text=html.unescape(r.text).replace('\\/','/')
                discovered += re.findall(r'https?://[^\"\'<> ]+(?:png|jpg|jpeg|webp)',text,re.I)
        except Exception: pass
        time.sleep(.4)
    direct=[url,
            f'https://i.resimyukle.xyz/{base}',
            f'https://resimyukle.xyz/i/{base}',
            f'https://resimyukle.xyz/images/{base}']+discovered
    seen=set()
    for u in direct:
        if u in seen: continue
        seen.add(u)
        for ref in ['https://resimyukle.xyz/', page_candidates[0]]:
            try:
                r=get(u,ref,30)
                if r.ok and kind(r.content): return r.content, f'direct:{r.url}'
            except Exception: pass
            time.sleep(.7)
    return wayback(url)

def recover_fztdulger(url):
    base=Path(urlparse(url).path).name
    terms=[base.rsplit('.',1)[0], base.split('-')[0]]
    discovered=[]
    for term in terms:
        for api in [
            'https://www.fztdulger.com/wp-json/wp/v2/media?per_page=100&search='+quote(term),
            'https://www.fztdulger.com/wp-json/wp/v2/search?per_page=20&subtype=post&search='+quote(term),
        ]:
            try:
                r=S.get(api,timeout=25)
                if r.ok:
                    text=html.unescape(r.text).replace('\\/','/')
                    discovered += re.findall(r'https?://[^\"\'<> ]+(?:jpg|jpeg|png|webp)',text,re.I)
            except Exception: pass
    for u in [url, url.replace('http://','https://')]+discovered:
        try:
            r=get(u,'https://www.fztdulger.com/',30)
            if r.ok and kind(r.content): return r.content, f'current:{r.url}'
        except Exception: pass
    return wayback(url)

def main():
    rows=list(csv.DictReader(open(MAN,encoding='utf-8'),delimiter='\t'))
    targets=[r for r in rows if ('resimyukle.xyz' in r['url'] or 'fztdulger.com' in r['url'] or r['url']=='https://hizliresim.com/vakoyv')]
    report=[]
    for i,r in enumerate(targets,1):
        url=r['url']; got=None
        if url=='https://hizliresim.com/vakoyv':
            # This exact page URL points to the same image as i.hizliresim.com/vakoyv.png; don't duplicate bytes here.
            report.append({**r,'state':'alias-known','method':'same-id:hizliresim/vakoyv','sha256':''}); continue
        if 'resimyukle.xyz' in url: got=recover_resimyukle(url)
        elif 'fztdulger.com' in url: got=recover_fztdulger(url)
        if got:
            data,method=got; out=IMG/r['local_name']; out.write_bytes(data)
            report.append({**r,'state':'ok','method':method,'sha256':hashlib.sha256(data).hexdigest()})
        else: report.append({**r,'state':'unresolved','method':'','sha256':''})
        print(i,len(targets),url,report[-1]['state'],flush=True)
        time.sleep(.5)
    fields=['source_json','local_name','url','state','method','sha256']
    with open(OUT/'report.tsv','w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields,delimiter='\t',extrasaction='ignore'); w.writeheader(); w.writerows(report)
    summary={'targets':len(report),'ok':sum(x['state']=='ok' for x in report),'alias_known':sum(x['state']=='alias-known' for x in report),'unresolved':sum(x['state']=='unresolved' for x in report)}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8'); print(json.dumps(summary),flush=True)
if __name__=='__main__': main()
