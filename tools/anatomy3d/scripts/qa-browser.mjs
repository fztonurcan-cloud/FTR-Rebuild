import fs from 'node:fs/promises';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const [url, outputDir, mode = 'assert'] = process.argv.slice(2);
const executablePath = process.env.CHROME_BIN;

if (!url || !outputDir || !executablePath) {
  throw new Error('Usage: CHROME_BIN=/path/to/chrome node qa-browser.mjs <url> <output-dir> <screenshot|assert>');
}

await fs.mkdir(outputDir, { recursive: true });

const browser = await puppeteer.launch({
  executablePath,
  headless: true,
  args: [
    '--no-sandbox',
    '--disable-dev-shm-usage',
    '--enable-unsafe-swiftshader'
  ]
});

try {
  const page = await browser.newPage();
  await page.setViewport({
    width: 390,
    height: 844,
    deviceScaleFactor: 1,
    isMobile: true,
    hasTouch: true
  });

  const qaUrl = new URL(url);
  qaUrl.searchParams.set('qa', '1');
  await page.goto(qaUrl.href, { waitUntil: 'domcontentloaded', timeout: 120_000 });
  await page.waitForFunction(
    () => document.documentElement.dataset.qaReady === 'true',
    { timeout: 120_000 }
  );

  const report = await page.$eval('#qa-layout-report', element => JSON.parse(element.textContent));
  await page.screenshot({
    path: path.join(outputDir, 'qa-phone.png'),
    type: 'png',
    captureBeyondViewport: false
  });
  await fs.writeFile(path.join(outputDir, 'qa-layout-dom.html'), await page.content(), 'utf8');
  await fs.writeFile(
    path.join(outputDir, 'qa-layout-report.json'),
    `${JSON.stringify(report, null, 2)}\n`,
    'utf8'
  );

  console.log(JSON.stringify(report, null, 2));

  if (report.viewport?.width !== 390 || report.viewport?.height !== 844) {
    throw new Error(`QA viewport mismatch: ${report.viewport?.width}x${report.viewport?.height}`);
  }
  if (mode === 'assert' && !report.pass) {
    throw new Error('LOCKED PHONE LAYOUT QA FAILED');
  }
  console.log(mode === 'assert' ? 'LOCKED PHONE LAYOUT QA PASS' : '390x844 QA screenshot captured');
} finally {
  await browser.close();
}
