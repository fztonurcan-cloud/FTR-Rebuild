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
  args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
});

async function runFunctionQa(page) {
  const checks = [];
  const record = (name, pass, detail = '') => {
    checks.push({ name, pass: Boolean(pass), detail });
    console.log(`[FUNCTION QA] ${pass ? 'PASS' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`);
  };
  const text = selector => page.$eval(selector, element => (element.textContent || '').trim());
  const waitReady = () => page.waitForFunction(() => {
    const state = window.__FTR_ANATOMY_QA__?.state?.();
    return state?.imageReady && document.getElementById('loading')?.classList.contains('hidden');
  }, { timeout: 120_000 });
  const waitHighlight = () => page.waitForFunction(() => window.__FTR_ANATOMY_QA__?.state?.().selectedHighlighted === true, { timeout: 30_000 });

  record('five_unique_systems', await page.evaluate(() => {
    const buttons = [...document.querySelectorAll('.system-btn')];
    return buttons.length === 5 && new Set(buttons.map(button => button.dataset.system)).size === 5 && Boolean(document.querySelector('.system-btn[data-system="nerve"]'));
  }));

  await waitReady();
  await waitHighlight();
  const initialState = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
  record('static_atlas_runtime', initialState.renderMode === 'static-layered-atlas' && initialState.webgl === false && initialState.runtime3dModels === false);
  record('initial_muscle_system', initialState.activeSystem === 'muscle' && initialState.activeStructureCount > 0, `${initialState.activeStructureCount} structure`);
  record('initial_biceps', (await text('#structureName')).toLowerCase().includes('biceps brachii') && initialState.selectedStructure.toLowerCase().includes('biceps brachii'), initialState.selectedStructure);
  record('initial_structure_highlight', initialState.selectedHighlighted, initialState.selectedStructure);
  record('no_continuous_render', initialState.continuousAnimation === false);
  record('legacy_model_controls_removed', await page.evaluate(() => !document.querySelector('.viewer-controls, #rotateBtn, #zoomInBtn, #zoomOutBtn, #autoRotateBtn')));

  const generalText = await text('#structureText');
  await page.click('.tab[data-tab="origin"]');
  const originText = await text('#structureText');
  record('muscle_semantic_tabs', originText !== generalText && originText.toLowerCase().includes('supraglenoid'), originText.slice(0, 80));
  await page.click('.tab[data-tab="general"]');

  const beforeZoom = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state().zoomScale);
  const afterZoom = await page.evaluate(() => window.__FTR_ANATOMY_QA__.zoom(2).zoomScale);
  record('pinch_zoom_engine', afterZoom > beforeZoom, `${beforeZoom} -> ${afterZoom}`);
  const resetZoom = await page.evaluate(() => window.__FTR_ANATOMY_QA__.resetView().zoomScale);
  record('zoom_reset', resetZoom === 1, String(resetZoom));

  const systems = [
    ['bone', 'KEMİK SİSTEMİ'],
    ['ligament', 'LİGAMENT SİSTEMİ'],
    ['vessel', 'DAMAR SİSTEMİ'],
    ['nerve', 'SİNİR SİSTEMİ'],
    ['muscle', 'KAS SİSTEMİ']
  ];
  for (const [key, title] of systems) {
    await page.click(`.system-btn[data-system="${key}"]`);
    await waitReady();
    const state = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
    const subtitle = await text('#systemSubtitle');
    record(`system_${key}`, state.activeSystem === key && state.activeStructureCount > 0 && subtitle.includes(title), `${subtitle} / ${state.activeStructureCount} structures`);
  }

  await page.click('.system-btn[data-system="bone"]');
  await waitReady();
  const fibula = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pick('^fibula'));
  await waitHighlight();
  record('fibula_target', fibula.selectedStructure.toLowerCase().startsWith('fibula'), fibula.selectedStructure);
  record('bone_tabs_correct', await page.evaluate(() =>
    Boolean(document.querySelector('.tab[data-tab="features"]')) &&
    Boolean(document.querySelector('.tab[data-tab="articulations"]')) &&
    !document.querySelector('.tab[data-tab="origin"]')
  ));
  await page.click('.tab[data-tab="features"]');
  record('fibula_anatomy_info', (await text('#structureText')).toLowerCase().includes('lateral malleol'));
  await page.click('.tab[data-tab="clinical"]');
  record('fibula_clinical_info', (await text('#structureText')).toLowerCase().includes('fibularis communis'));

  await page.click('.system-btn[data-system="ligament"]');
  await waitReady();
  const atfl = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pick('anterior\\s+talofibular|talofibular\\s+anterior|atfl'));
  await waitHighlight();
  record('atfl_target', /talofibular|atfl/i.test(atfl.selectedStructure), atfl.selectedStructure);
  record('ligament_tabs_correct', await page.evaluate(() =>
    Boolean(document.querySelector('.tab[data-tab="attachments"]')) && Boolean(document.querySelector('.tab[data-tab="clinical"]')) && !document.querySelector('.tab[data-tab="origin"]')
  ));

  await page.click('.system-btn[data-system="vessel"]');
  await waitReady();
  const artery = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pick('anterior\\s+tibial\\s+arter'));
  await waitHighlight();
  record('anterior_tibial_target', /anterior\s+tibial\s+arter/i.test(artery.selectedStructure), artery.selectedStructure);
  record('vessel_tabs_correct', await page.evaluate(() =>
    Boolean(document.querySelector('.tab[data-tab="course"]')) && Boolean(document.querySelector('.tab[data-tab="branches"]')) && Boolean(document.querySelector('.tab[data-tab="supply"]')) && !document.querySelector('.tab[data-tab="insertion"]')
  ));

  await page.click('.system-btn[data-system="nerve"]');
  await waitReady();
  const median = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pick('median\\s+nerve|medianus'));
  await waitHighlight();
  record('median_nerve_target', /median\s+nerve|medianus/i.test(median.selectedStructure), median.selectedStructure);
  record('nerve_tabs_correct', await page.evaluate(() =>
    Boolean(document.querySelector('.tab[data-tab="anatomy"]')) && Boolean(document.querySelector('.tab[data-tab="course"]')) && Boolean(document.querySelector('.tab[data-tab="innervation"]')) && Boolean(document.querySelector('.tab[data-tab="clinical"]'))
  ));
  record('median_info_card', (await text('#structureName')).toLowerCase().includes('median'));

  await page.click('.system-btn[data-system="ligament"]');
  await page.click('.system-btn[data-system="vessel"]');
  await page.click('.system-btn[data-system="nerve"]');
  await waitReady();
  const raceState = await page.evaluate(() => window.__FTR_ANATOMY_QA__.state());
  record('rapid_switch_latest_wins', raceState.activeSystem === 'nerve', `${raceState.activeSystem} / ${raceState.selectedStructure}`);
  record('low_end_render_budget', raceState.pixelRatio === 1 && raceState.continuousAnimation === false && raceState.webgl === false && raceState.runtime3dModels === false,
    `webgl=${raceState.webgl} pixelRatio=${raceState.pixelRatio}`);

  return { pass: checks.every(check => check.pass), checks };
}

try {
  const page = await browser.newPage();
  await page.setViewport({ width: qaWidth, height: qaHeight, deviceScaleFactor: 1, isMobile: true, hasTouch: true });

  const qaUrl = new URL(url);
  qaUrl.searchParams.set('qa', '1');
  await page.goto(qaUrl.href, { waitUntil: 'domcontentloaded', timeout: 120_000 });
  await page.waitForFunction(() => document.documentElement.dataset.qaReady === 'true', { timeout: 120_000 });

  if (mode === 'function') {
    const report = await runFunctionQa(page);
    await page.screenshot({ path: path.join(outputDir, 'qa-function.png'), type: 'png', fullPage: true });
    await fs.writeFile(path.join(outputDir, 'qa-function-report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
    if (!report.pass) throw new Error('ANATOMY STATIC ATLAS FUNCTION QA FAILED');
    console.log('ANATOMY STATIC ATLAS FUNCTION QA PASS');
  } else {
    const report = await page.$eval('#qa-layout-report', element => JSON.parse(element.textContent));
    await page.screenshot({ path: path.join(outputDir, 'qa-phone.png'), type: 'png', fullPage: true });
    await fs.writeFile(path.join(outputDir, 'qa-layout-dom.html'), await page.content(), 'utf8');
    await fs.writeFile(path.join(outputDir, 'qa-layout-report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));

    if (report.viewport?.width !== qaWidth || report.viewport?.height !== qaHeight) {
      throw new Error(`QA viewport mismatch: ${report.viewport?.width}x${report.viewport?.height}; expected ${qaWidth}x${qaHeight}`);
    }
    if (mode === 'assert' && !report.pass) throw new Error('PREMIUM PHONE LAYOUT QA FAILED');
    console.log(mode === 'assert' ? `PREMIUM PHONE LAYOUT QA PASS (${qaWidth}x${qaHeight})` : `${qaWidth}x${qaHeight} QA screenshot captured`);
  }
} finally {
  await browser.close();
}
