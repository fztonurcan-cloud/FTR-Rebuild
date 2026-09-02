import fs from 'node:fs/promises';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const [url, outputDir, mode = 'assert'] = process.argv.slice(2);
const executablePath = process.env.CHROME_BIN;
const qaWidth = Number(process.env.QA_WIDTH || 390);
const qaHeight = Number(process.env.QA_HEIGHT || 844);

if (!url || !outputDir || !executablePath) {
  throw new Error('Usage: CHROME_BIN=/path/to/chrome node qa-browser.mjs <url> <output-dir> <screenshot|assert|function>');
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

async function runFunctionQa(page) {
  const checks = [];
  const record = (name, pass, detail = '') => {
    checks.push({ name, pass: Boolean(pass), detail });
    console.log(`[FUNCTION QA] ${pass ? 'PASS' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`);
  };
  const text = selector => page.$eval(selector, element => (element.textContent || '').trim());
  const waitForLoading = () => page.waitForFunction(
    () => document.getElementById('loading')?.classList.contains('hidden'),
    { timeout: 120_000 }
  );

  record('simplified_controls_only', await page.evaluate(() =>
    !document.querySelector('#examBtn, #quizCard, .learn-chip, .view-panel, .tool-panel') &&
    document.querySelectorAll('.system-btn').length === 4
  ));
  record('initial_biceps', (await text('#structureName')).toLowerCase().includes('biceps brachii'));
  record('initial_muscle_system', (await text('.system-btn.active')).includes('Kaslar'));

  const generalText = await text('#structureText');
  await page.click('.tab[data-tab="origin"]');
  const originText = await text('#structureText');
  record('anatomy_info_tabs', originText !== generalText && originText.length > 20);
  await page.click('.tab[data-tab="general"]');

  const stateBeforeZoom = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
  await page.click('#zoomInBtn');
  const stateAfterZoom = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
  record('zoom_in_changes_model_view', stateAfterZoom.cameraDistance < stateBeforeZoom.cameraDistance, `${stateBeforeZoom.cameraDistance} -> ${stateAfterZoom.cameraDistance}`);
  await page.click('#zoomOutBtn');
  await page.click('#resetBtn');
  const rotationBefore = (await page.evaluate(() => window.__FTR_ANATOMY_QA__.state())).activeRotationY;
  await page.click('#rotateBtn');
  await new Promise(resolve => setTimeout(resolve, 350));
  const rotationAfter = (await page.evaluate(() => window.__FTR_ANATOMY_QA__.state())).activeRotationY;
  record('single_step_rotate', rotationAfter > rotationBefore + 0.5, `${rotationBefore} -> ${rotationAfter}`);

  const initialStructure = await text('#structureName');
  const pickedState = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pickDifferentStructure());
  record('structure_selection', pickedState.selectedStructure !== initialStructure, `${initialStructure} -> ${pickedState.selectedStructure}`);
  record('selected_structure_highlight', pickedState.selectedHighlighted, pickedState.selectedStructure);

  const systems = [
    ['ligament', 'Ligamentler'],
    ['vessel', 'Damarlar'],
    ['bone', 'Kemikler'],
    ['muscle', 'Kaslar']
  ];
  for (const [key, label] of systems) {
    await page.click(`.system-btn[data-system="${key}"]`);
    await waitForLoading();
    await page.waitForFunction(
      (system, expected) => document.querySelector('.system-btn.active')?.dataset.system === system && document.getElementById('systemHeading')?.textContent.includes(expected),
      {},
      key,
      label
    );
    const systemState = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
    record(`system_${key}`, (await text('#systemHeading')).includes(label) && systemState.activeSystem === key && systemState.activeMeshCount > 0, `${await text('#structureName')} (${systemState.activeMeshCount} mesh)`);
  }

  await page.click('.system-btn[data-system="bone"]');
  await waitForLoading();
  const fibula = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pick('^fibula$'));
  record('fibula_click_target', fibula.selectedStructure.toLowerCase() === 'fibula', fibula.selectedStructure);
  record('fibula_general_info', (await text('#structureText')).toLowerCase().includes('bacağın lateralinde'));
  await page.click('.tab[data-tab="origin"]');
  record('fibula_origin_info', (await text('#structureText')).toLowerCase().includes('fibularis longus'));
  await page.click('.tab[data-tab="insertion"]');
  record('fibula_insertion_info', (await text('#structureText')).toLowerCase().includes('biceps femoris'));
  await page.click('.tab[data-tab="innervation"]');
  record('fibula_innervation_info', (await text('#structureText')).toLowerCase().includes('motor innervasyon almaz'));
  await page.click('.tab[data-tab="function"]');
  record('fibula_function_info', (await text('#structureText')).toLowerCase().includes('ayak bileğinin lateral stabilitesini'));

  await page.click('.system-btn[data-system="ligament"]');
  await page.click('.system-btn[data-system="vessel"]');
  await page.click('.system-btn[data-system="bone"]');
  await waitForLoading();
  const raceState = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
  record('rapid_switch_keeps_latest_system', raceState.activeSystem === 'bone' && raceState.selectedStructure.toLowerCase() === 'fibula', `${raceState.activeSystem} / ${raceState.selectedStructure}`);
  record('mobile_render_budget', raceState.pixelRatio <= 1 && raceState.continuousAnimation === false, `pixelRatio=${raceState.pixelRatio}`);

  return { pass: checks.every(check => check.pass), checks };
}

try {
  const page = await browser.newPage();
  await page.setViewport({
    width: qaWidth,
    height: qaHeight,
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

  if (mode === 'function') {
    const report = await runFunctionQa(page);
    await page.screenshot({ path: path.join(outputDir, 'qa-function.png'), type: 'png', captureBeyondViewport: false });
    await fs.writeFile(path.join(outputDir, 'qa-function-report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
    if (!report.pass) throw new Error('3D ANATOMY FUNCTION QA FAILED');
    console.log('3D ANATOMY FUNCTION QA PASS');
  } else {
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

    if (report.viewport?.width !== qaWidth || report.viewport?.height !== qaHeight) {
      throw new Error(`QA viewport mismatch: ${report.viewport?.width}x${report.viewport?.height}; expected ${qaWidth}x${qaHeight}`);
    }
    if (mode === 'assert' && !report.pass) {
      throw new Error('LOCKED PHONE LAYOUT QA FAILED');
    }
    console.log(mode === 'assert' ? `LOCKED PHONE LAYOUT QA PASS (${qaWidth}x${qaHeight})` : `${qaWidth}x${qaHeight} QA screenshot captured`);
  }
} finally {
  await browser.close();
}
