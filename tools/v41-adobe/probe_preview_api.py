#!/usr/bin/env python3
import csv,json,re,urllib.parse,requests
from pathlib import Path
MAN=Path('/tmp/ftr-v41-manifests/adobe_links.tsv')
S=requests.Session(); S.headers.update({'User-Agent':'Mozilla/5.0','Accept':'application/json,text/plain,*/*','Origin':'https://acrobat.adobe.com','Referer':'https://acrobat.adobe.com/'})

def strings(obj,path=''):
    if isinstance(obj,dict):
        for k,v in obj.items(): yield from strings(v,path+'/'+str(k))
    elif isinstance(obj,list):
        for i,v in enumerate(obj): yield from strings(v,path+'/'+str(i))
    elif isinstance(obj,str): yield path,obj

for row in list(csv.DictReader(open(MAN,encoding='utf-8'),delimiter='\t'))[:5]:
    urn='urn:aaid:scds:US:'+row['urn_id']
    u='https://send-asr.acrobat.com/a/invitation/'+urllib.parse.quote(urn,safe='')+'/asset/asset-0/preview'
    r=S.get(u,timeout=30)
    print('\n###',row['urn_id'],r.status_code,r.headers.get('content-type'),len(r.content))
    try:
        j=r.json()
        for p,s in strings(j):
            if ('http' in s.lower() or 'ticket' in p.lower() or 'asset' in p.lower() or 'mime' in p.lower() or 'name' in p.lower()):
                print(p,repr(s[:1000]))
    except Exception as e: print('JSONERR',e,repr(r.text[:2000]))
