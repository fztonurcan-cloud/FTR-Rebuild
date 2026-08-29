#!/usr/bin/env python3
import asyncio,csv,hashlib,json,re,urllib.parse
from pathlib import Path
from playwright.async_api import async_playwright

MAN=Path('/tmp/ftr-v41-manifests/adobe_links.tsv')
OUT=Path('/tmp/ftr-v41-adobe-retry7'); FILES=OUT/'originals'; FILES.mkdir(parents=True,exist_ok=True)
TARGETS={'53f1eca2-7ac5-4275-a79e-2aa5a007c21d','da360670-cea4-4be6-9345-c429f8a77c01','10d56378-561f-4f1c-90d7-7672d445f1b1','ad1046f7-1149-4c54-b82c-1481d922c341','430d7b41-4278-4850-a1ad-3b886c186f69','aced8420-bea9-4512-b29f-c33bbaceb96e','3d2150ad-093b-4f1d-b3bf-5d3e3854e39f'}
MIME_EXT={'application/pdf':'.pdf','application/vnd.openxmlformats-officedocument.presentationml.presentation':'.pptx','application/vnd.ms-powerpoint':'.ppt'}

def fn_cd(cd):
 m=re.search(r"filename\*=(?:UTF-8'')?([^;]+)",cd or '',re.I)
 if m:return urllib.parse.unquote(m.group(1).strip().strip('"'))
 m=re.search(r'filename=([^;]+)',cd or '',re.I)
 return urllib.parse.unquote(urllib.parse.unquote(m.group(1).strip().strip('"'))) if m else ''

def valid(data,ext,ct):
 if ext=='.pdf' or ct=='application/pdf':return data.startswith(b'%PDF')
 if ext=='.pptx' or 'openxmlformats' in ct:return data.startswith(b'PK')
 if ext=='.ppt':return data.startswith(bytes.fromhex('D0CF11E0A1B11AE1'))
 return False

async def one(browser,row):
 urn=row['urn_id']; share=row['url']; out={'source_json':row['source_json'],'urn_id':urn,'share_url':share,'state':'miss','title':'','filename':'','mime':'','bytes':0,'sha256':'','detail':''}
 for attempt in range(1,6):
  ctx=await browser.new_context(locale='tr-TR',accept_downloads=True,viewport={'width':1440,'height':1000})
  p=await ctx.new_page(); hit=asyncio.Event(); cap={}; lock=asyncio.Lock()
  async def resp(r):
   if hit.is_set():return
   try:
    h=await r.all_headers();ct=(h.get('content-type') or '').split(';')[0].lower();cd=h.get('content-disposition') or '';fn=fn_cd(cd);ext=Path(fn).suffix.lower() if fn else MIME_EXT.get(ct,'')
    if not (('attachment' in cd.lower()) or ct in MIME_EXT or ext in MIME_EXT.values()):return
    data=await r.body()
    if not valid(data,ext,ct):return
    async with lock:
     if hit.is_set():return
     ext=ext or MIME_EXT.get(ct,'.bin'); path=FILES/f'{urn}{ext}';path.write_bytes(data)
     cap.update(filename=fn or path.name,mime=ct,bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),url=r.url,path=path.name);hit.set()
   except Exception:pass
  p.on('response',resp)
  try:
   await p.goto(share,wait_until='domcontentloaded',timeout=90000); await p.wait_for_timeout(12000)
   try:out['title']=await p.title()
   except:pass
   # interact repeatedly; some shares delay the original request until toolbar/menu/scroll.
   for cycle in range(4):
    if hit.is_set():break
    try:await p.mouse.wheel(0,1600*(cycle+1))
    except:pass
    await p.wait_for_timeout(2500)
    for sel in ['button[aria-label*="More" i]','button[title*="More" i]','button[aria-label*="menu" i]','button[aria-label*="download" i]','button[title*="download" i]']:
     try:
      loc=p.locator(sel).first
      if await loc.count() and await loc.is_visible():await loc.click(timeout=2500);await p.wait_for_timeout(1500)
     except:pass
    for txt in ['Download this file','Download','Save a copy','İndir']:
     try:
      loc=p.get_by_text(txt,exact=False).first
      if await loc.count() and await loc.is_visible():await loc.click(timeout=3000);await p.wait_for_timeout(4000)
     except:pass
   if not hit.is_set():
    try:await asyncio.wait_for(hit.wait(),timeout=25)
    except asyncio.TimeoutError:pass
   if hit.is_set():
    out.update(state='ok',filename=cap['filename'],mime=cap['mime'],bytes=cap['bytes'],sha256=cap['sha256'],detail=f'attempt={attempt}; source={cap["url"]}; path={cap["path"]}')
    await ctx.close();return out
  except Exception as e:out['detail']=type(e).__name__+':'+str(e)[:400]
  await ctx.close()
 return out

async def main():
 rows=[r for r in csv.DictReader(open(MAN,encoding='utf-8'),delimiter='\t') if r['urn_id'] in TARGETS]
 async with async_playwright() as pw:
  b=await pw.chromium.launch(headless=True,args=['--disable-dev-shm-usage','--no-sandbox'])
  results=[]
  for r in rows:
   x=await one(b,r);results.append(x);print(x['state'],x['urn_id'],x['title'],x['mime'],x['bytes'],flush=True)
  await b.close()
 fields=['source_json','urn_id','share_url','state','title','filename','mime','bytes','sha256','detail']
 with open(OUT/'report.tsv','w',newline='',encoding='utf-8') as f:
  w=csv.DictWriter(f,fieldnames=fields,delimiter='\t');w.writeheader();w.writerows(results)
 (OUT/'summary.json').write_text(json.dumps({'total':len(results),'ok':sum(x['state']=='ok' for x in results),'miss':sum(x['state']!='ok' for x in results)},indent=2),encoding='utf-8')
if __name__=='__main__':asyncio.run(main())
