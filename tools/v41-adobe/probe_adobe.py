#!/usr/bin/env python3
import asyncio,csv,json,re
from pathlib import Path
from playwright.async_api import async_playwright, TimeoutError as PlaywrightTimeoutError

MAN=Path('/tmp/ftr-v41-manifests/adobe_links.tsv'); OUT=Path('/tmp/ftr-v41-adobe-probe'); OUT.mkdir(parents=True,exist_ok=True)

async def probe(browser,row):
    urn=row['urn_id']; url=row['url']; ctx=await browser.new_context(locale='en-US',accept_downloads=True)
    page=await ctx.new_page(); events=[]; saved=[]
    async def on_response(resp):
        try:
            ct=(await resp.header_value('content-type') or '').lower(); u=resp.url
            if ('pdf' in ct or any(x in u.lower() for x in ['download','asset','content','document','pdf'])):
                events.append({'url':u,'status':resp.status,'content_type':ct})
            if 'application/pdf' in ct:
                b=await resp.body(); p=OUT/f'{urn}.network.pdf'; p.write_bytes(b); saved.append(str(p.name))
        except Exception: pass
    page.on('response',on_response)
    result={'urn_id':urn,'url':url,'final_url':'','title':'','saved':saved,'events':events,'buttons':[],'body_text':'','error':''}
    try:
        await page.goto(url,wait_until='domcontentloaded',timeout=60000)
        await page.wait_for_timeout(12000)
        result['final_url']=page.url; result['title']=await page.title()
        try: result['body_text']=(await page.locator('body').inner_text())[:12000]
        except Exception: pass
        try: result['buttons']=(await page.locator('button').all_inner_texts())[:100]
        except Exception: pass
        # open likely overflow/menu controls first
        for sel in ['button[aria-label*="More"]','button[title*="More"]','button[aria-label*="menu" i]','button[aria-label*="options" i]']:
            try:
                loc=page.locator(sel).first
                if await loc.count(): await loc.click(timeout=2500); await page.wait_for_timeout(1200); break
            except Exception: pass
        # try visible download entry
        for text in ['Download this file','Download','Save a copy']:
            try:
                loc=page.get_by_text(text,exact=False).first
                if await loc.count() and await loc.is_visible():
                    async with page.expect_download(timeout=10000) as di:
                        await loc.click()
                    dl=await di.value; p=OUT/f'{urn}.download.pdf'; await dl.save_as(str(p)); saved.append(p.name); break
            except Exception as e:
                events.append({'download_attempt':text,'error':type(e).__name__+':'+str(e)[:300]})
        result['saved']=saved; result['events']=events
        (OUT/f'{urn}.html').write_text(await page.content(),encoding='utf-8')
    except Exception as e: result['error']=type(e).__name__+':'+str(e)
    await ctx.close(); return result

async def main():
    rows=list(csv.DictReader(open(MAN,encoding='utf-8'),delimiter='\t'))[:3]
    async with async_playwright() as p:
        browser=await p.chromium.launch(headless=True,args=['--disable-dev-shm-usage','--no-sandbox'])
        results=[]
        for row in rows:
            r=await probe(browser,row); results.append(r); print(json.dumps({k:r[k] for k in ['urn_id','final_url','title','saved','error']},ensure_ascii=False),flush=True)
        await browser.close()
    (OUT/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__': asyncio.run(main())
