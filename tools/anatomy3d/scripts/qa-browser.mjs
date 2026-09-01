import fs from 'node:fs/promises';
import path from 'node:path';
import puppeteer from 'puppeteer-core';

const [url, outputDir, mode = 'assert'] = process.argv.slice(2);
const executablePath = process.env.CHROME_BIN;

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

  record('initial_biceps', (await text('#structureName')).toLowerCase().includes('biceps brachii'));
  record('initial_muscle_system', (await text('.system-btn.active')).includes('Kas Sistemi'));

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
  await page.click('#rotateBtn');
  await page.waitForFunction(() => document.getElementById('anatomyToast')?.textContent.includes('açık'));
  record('rotate_toggle', true, await text('#anatomyToast'));
  await page.click('#rotateBtn');

  const initialStructure = await text('#structureName');
  const pickedState = await page.evaluate(() => window.__FTR_ANATOMY_QA__.pickDifferentStructure());
  record('canvas_structure_selection', pickedState.selectedStructure !== initialStructure, `${initialStructure} -> ${pickedState.selectedStructure}`);
  record('selected_structure_highlight', pickedState.selectedHighlighted, pickedState.selectedStructure);

  const systems = [
    ['nerve', 'Sinir Sistemi'],
    ['ligament', 'Ligament Sistemi'],
    ['vessel', 'Damar Sistemi'],
    ['muscle', 'Kas Sistemi']
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

  await page.click('#examBtn');
  await page.waitForFunction(() => !document.getElementById('quizCard')?.classList.contains('hidden') && document.querySelectorAll('.quiz-option').length >= 4);
  record('exam_mode_opens', (await text('#examBtn')).includes('Öğrenme Modu'));
  const regularProgress = await text('#quizProgress');
  await page.click('.quiz-option');
  record('exam_answer_feedback', (await text('#quizFeedback')).length > 0);
  await page.click('#nextQuestionBtn');
  await page.waitForFunction(previous => document.getElementById('quizProgress')?.textContent !== previous, {}, regularProgress);
  record('exam_next_question', true, await text('#quizProgress'));

  await page.click('#mixedExamBtn');
  await page.waitForFunction(() => document.getElementById('mixedExamBtn')?.classList.contains('active') && document.querySelectorAll('.quiz-option').length >= 4, { timeout: 120_000 });
  const mixedSystemOne = await text('#quizSystem');
  await page.click('.quiz-option');
  await page.click('#nextQuestionBtn');
  await page.waitForFunction(
    previous => document.getElementById('quizSystem')?.textContent !== previous && document.getElementById('quizProgress')?.textContent.startsWith('Soru 2'),
    { timeout: 120_000 },
    mixedSystemOne
  );
  record('mixed_exam_cross_system', true, `${mixedSystemOne} -> ${await text('#quizSystem')}`);

  await page.click('#examBtn');
  await page.waitForFunction(() => !document.getElementById('infoCard')?.classList.contains('hidden'));
  record('learning_mode_returns', (await text('#examBtn')).includes('Sınav Modu'));

  return { pass: checks.every(check => check.pass), checks };
}

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

    if (report.viewport?.width !== 390 || report.viewport?.height !== 844) {
      throw new Error(`QA viewport mismatch: ${report.viewport?.width}x${report.viewport?.height}`);
    }
    if (mode === 'assert' && !report.pass) {
      throw new Error('LOCKED PHONE LAYOUT QA FAILED');
    }
    console.log(mode === 'assert' ? 'LOCKED PHONE LAYOUT QA PASS' : '390x844 QA screenshot captured');
  }
} finally {
  await browser.close();
}
