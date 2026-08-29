#!/usr/bin/env python3
import asyncio, json, hashlib
from pathlib import Path
from playwright.async_api import async_playwright

ITEMS=[
('2027148.json','da360670-cea4-4be6-9345-c429f8a77c01','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:da360670-cea4-4be6-9345-c429f8a77c01'),
('2034944.json','3d2150ad-093b-4f1d-b3bf-5d3e3854e39f','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:3d2150ad-093b-4f1d-b3bf-5d3e3854e39f'),
('2056881.json','ad1046f7-1149-4c54-b82c-1481d922c341','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:ad1046f7-1149-4c54-b82c-1481d922c341'),
('2054757.json','53f1eca2-7ac5-4275-a79e-2aa5a007c21d','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:53f1eca2-7ac5-4275-a79e-2aa5a007c21d'),
('2034929.json','aced8420-bea9-4512-b29f-c33bbaceb96e','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:aced8420-bea9-4512-b29f-c33bbaceb96e'),
('2027431.json','10d56378-561f-4f1c-90d7-7672d445f1b1','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:10d56378-561f-4f1c-90d7-7672d445f1b1'),
('2034271.json','430d7b41-4278-4850-a1ad-3b886c186f69','https://documentcloud.adobe.com/link/track?uri=urn:aaid:scds:US:430d7b41-4278-4850-a1ad-3b886c186f69'),
]
OUT=Path('/tmp/ftr-adobe7'); OUT.mkdir(parents=True,exist_ok=True)

def valid(body): return len(body)>2000 and (body.startswith(b'%PDF') or body.startswith(b'PK\x03\x04'))

async def one(browser,item):
    src,urn,url=item
    ctx=await browser.new_context(accept_downloads=True,locale='tr-TR')
    page=await ctx.new_page(); candidates=[]; errors=[]
    async def on_response(resp):
        try:
            h=await resp.all_headers(); ct=h.get('content-type','').lower(); u=resp.url.lower()
            if ('blobstore' in u or 'adobe.io' in u) and ('pdf' in ct or 'officedocument' in ct or 'ms-powerpoint' in ct or 'application/octet-stream' in ct):
                candidates.append({'url':resp.url,'ct':ct,'headers':h})
        except Exception: pass
    page.on('response',on_response)
    best=None
    try:
        await page.goto(url,wait_until='domcontentloaded',timeout=90000)
        await page.wait_for_timeout(10000)
        # First retry captured signed blob URLs through the browser context request client.
        seen=set()
        for c in candidates:
            if c['url'] in seen: continue
            seen.add(c['url'])
            try:
                r=await ctx.request.get(c['url'],headers={'referer':page.url},timeout=90000,fail_on_status_code=False)
                body=await r.body()
                if valid(body) and (best is None or len(body)>len(best[1])): best=(c,body,r.headers.get('content-type',''))
            except Exception as e: errors.append('api:'+type(e).__name__+':'+str(e)[:180])
        # If needed, trigger download controls and retry any newly observed signed URLs.
        if best is None:
            for sel in ['button[aria-label*="Download" i]','button[title*="Download" i]','[data-testid*="download" i]','text=/download|indir/i']:
                try:
                    loc=page.locator(sel).first
                    if await loc.count(): await loc.click(timeout=2500); await page.wait_for_timeout(5000); break
                except Exception as e: errors.append('click:'+str(e)[:150])
            for c in candidates:
                if c['url'] in seen: continue
                seen.add(c['url'])
                try:
                    r=await ctx.request.get(c['url'],headers={'referer':page.url},timeout=90000,fail_on_status_code=False)
                    body=await r.body()
                    if valid(body) and (best is None or len(body)>len(best[1])): best=(c,body,r.headers.get('content-type',''))
                except Exception as e: errors.append('api2:'+type(e).__name__+':'+str(e)[:180])
        if best:
            c,body,ct=best; ext='.pdf' if body.startswith(b'%PDF') else '.pptx'
            p=OUT/(urn+ext); p.write_bytes(body)
            rec={'source_json':src,'urn_id':urn,'state':'ok','url':url,'captured_url':c['url'],'content_type':ct,'bytes':len(body),'sha256':hashlib.sha256(body).hexdigest(),'file':p.name,'candidate_count':len(candidates),'errors':errors}
        else:
            rec={'source_json':src,'urn_id':urn,'state':'miss','url':url,'candidate_count':len(candidates),'candidate_urls':[c['url'] for c in candidates[:8]],'errors':errors,'title':await page.title()}
    except Exception as e:
        rec={'source_json':src,'urn_id':urn,'state':'error','url':url,'errors':errors+[repr(e)]}
    await ctx.close(); return rec

async def main():
    async with async_playwright() as p:
        browser=await p.chromium.launch(headless=True)
        out=[]
        for item in ITEMS:
            r=await one(browser,item); out.append(r); print(json.dumps(r,ensure_ascii=False),flush=True)
        await browser.close()
    (OUT/'status.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
    (OUT/'summary.json').write_text(json.dumps({'total':len(out),'ok':sum(r['state']=='ok' for r in out),'miss':sum(r['state']!='ok' for r in out)},indent=2))

asyncio.run(main())
