#!/usr/bin/env python3
import asyncio,csv,hashlib,json,mimetypes,os,re,urllib.parse
from pathlib import Path
from playwright.async_api import async_playwright

MAN=Path('/tmp/ftr-v41-manifests/adobe_links.tsv')
ROOT=Path('/tmp/ftr-v41-adobe-batch')
FILES=ROOT/'originals'; FILES.mkdir(parents=True,exist_ok=True)
SHARD=int(os.environ.get('SHARD_INDEX','0')); COUNT=int(os.environ.get('SHARD_COUNT','6'))
CONC=int(os.environ.get('CONCURRENCY','3'))

MIME_EXT={
'application/pdf':'.pdf',
'application/vnd.openxmlformats-officedocument.presentationml.presentation':'.pptx',
'application/vnd.ms-powerpoint':'.ppt',
'application/vnd.openxmlformats-officedocument.wordprocessingml.document':'.docx',
'application/msword':'.doc',
'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':'.xlsx',
'application/vnd.ms-excel':'.xls',
'application/rtf':'.rtf',
}

def safe_name(s):
    s=re.sub(r'[\\/:*?"<>|\x00-\x1f]+','_',s).strip(' .')
    return s[:180] or 'document'

def filename_from_cd(cd):
    if not cd:return ''
    m=re.search(r"filename\*=(?:UTF-8'')?([^;]+)",cd,re.I)
    if m:
        return urllib.parse.unquote(m.group(1).strip().strip('"'))
    m=re.search(r'filename=([^;]+)',cd,re.I)
    if m:
        return urllib.parse.unquote(urllib.parse.unquote(m.group(1).strip().strip('"')))
    return ''

def magic_ok(data,ext,ct):
    if ext=='.pdf' or ct=='application/pdf': return data.startswith(b'%PDF')
    if ext in {'.pptx','.docx','.xlsx'} or 'openxmlformats' in ct: return data.startswith(b'PK')
    if ext in {'.ppt','.doc','.xls'}: return data.startswith(bytes.fromhex('D0CF11E0A1B11AE1'))
    if ext=='.rtf': return data.startswith(b'{\\rtf')
    return len(data)>1024

async def capture_one(browser,row,sem):
  async with sem:
    urn=row['urn_id']; share=row['url']; result={'source_json':row['source_json'],'urn_id':urn,'share_url':share,'state':'miss','title':'','filename':'','mime':'','bytes':0,'sha256':'','detail':''}
    for attempt in range(1,4):
      ctx=await browser.new_context(locale='en-US',accept_downloads=True)
      page=await ctx.new_page(); found=asyncio.Event(); lock=asyncio.Lock(); captured={}
      async def on_resp(resp):
        if found.is_set(): return
        try:
          h=await resp.all_headers(); ct=(h.get('content-type') or '').split(';')[0].lower().strip(); cd=h.get('content-disposition') or ''
          fn=filename_from_cd(cd)
          ext=Path(fn).suffix.lower() if fn else MIME_EXT.get(ct,'')
          qualifies=('attachment' in cd.lower()) or ct in MIME_EXT or ext in set(MIME_EXT.values())
          if not qualifies:return
          data=await resp.body()
          if not magic_ok(data,ext,ct): return
          async with lock:
            if found.is_set():return
            if not ext: ext=MIME_EXT.get(ct,'.bin')
            label=safe_name(Path(fn).stem if fn else urn)
            out=FILES/f'{urn}__{label}{ext}'
            out.write_bytes(data)
            captured.update(filename=fn or out.name,mime=ct,bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),path=out.name,url=resp.url)
            found.set()
        except Exception: pass
      page.on('response',on_resp)
      try:
        await page.goto(share,wait_until='domcontentloaded',timeout=60000)
        try: result['title']=await page.title()
        except Exception: pass
        try:
          await asyncio.wait_for(found.wait(),timeout=18)
        except asyncio.TimeoutError:
          # Viewer sometimes waits for interaction before requesting the original asset.
          try: await page.mouse.wheel(0,1200)
          except Exception: pass
          for sel in ['button[aria-label*="More" i]','button[title*="More" i]','button[aria-label*="menu" i]']:
            try:
              loc=page.locator(sel).first
              if await loc.count() and await loc.is_visible(): await loc.click(timeout=2000); await page.wait_for_timeout(800); break
            except Exception: pass
          for txt in ['Download this file','Download','Save a copy']:
            try:
              loc=page.get_by_text(txt,exact=False).first
              if await loc.count() and await loc.is_visible(): await loc.click(timeout=3000); break
            except Exception: pass
          try: await asyncio.wait_for(found.wait(),timeout=14)
          except asyncio.TimeoutError: pass
        if found.is_set():
          result.update(state='ok',filename=captured['filename'],mime=captured['mime'],bytes=captured['bytes'],sha256=captured['sha256'],detail='path='+captured['path']+'; attempt='+str(attempt)+'; source='+captured['url'])
          await ctx.close(); return result
      except Exception as e:
        result['detail']=type(e).__name__+':'+str(e)[:400]
      await ctx.close()
    return result

async def main():
    allrows=list(csv.DictReader(open(MAN,encoding='utf-8'),delimiter='\t'))
    rows=[r for i,r in enumerate(allrows) if i%COUNT==SHARD]
    sem=asyncio.Semaphore(CONC)
    async with async_playwright() as p:
      browser=await p.chromium.launch(headless=True,args=['--disable-dev-shm-usage','--no-sandbox'])
      tasks=[asyncio.create_task(capture_one(browser,r,sem)) for r in rows]
      results=[]
      for fut in asyncio.as_completed(tasks):
        r=await fut; results.append(r); print(r['state'],r['urn_id'],r['mime'],r['bytes'],r['title'],flush=True)
      await browser.close()
    results.sort(key=lambda x:x['source_json'])
    fields=['source_json','urn_id','share_url','state','title','filename','mime','bytes','sha256','detail']
    with open(ROOT/f'report-shard-{SHARD}.tsv','w',newline='',encoding='utf-8') as f:
      w=csv.DictWriter(f,fieldnames=fields,delimiter='\t');w.writeheader();w.writerows(results)
    summary={'shard':SHARD,'total':len(results),'ok':sum(r['state']=='ok' for r in results),'miss':sum(r['state']!='ok' for r in results),'bytes':sum(int(r['bytes'] or 0) for r in results)}
    (ROOT/f'summary-shard-{SHARD}.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    print(json.dumps(summary),flush=True)
if __name__=='__main__':asyncio.run(main())
