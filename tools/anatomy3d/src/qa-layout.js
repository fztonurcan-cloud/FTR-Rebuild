const params = new URLSearchParams(location.search);

if (params.get('qa') === '1') {
  const started = performance.now();
  const deadlineMs = 30000;
  const requiredLabels = [
    '3D ANATOMİ', 'SİSTEM SEÇİMİ', 'Kaslar', 'Ligamentler', 'Damarlar', 'Kemikler',
    'MODEL KONTROLLERİ', 'Döndür', 'Yakınlaştır', 'Uzaklaştır', 'Sıfırla',
    'Biceps brachii', 'Genel Bilgi', 'Origo', 'Insertio', 'İnnervasyon', 'Fonksiyon'
  ];
  const forbiddenLabels = ['Sınav Modu', 'Karma Sınav', 'Öğrenme Modu', 'Sinir Sistemi', 'GÖRÜNÜM', 'Etiketler', 'Not Ekle', 'Bilgiyi Paylaş'];
  const targets = {
    app: '#anatomy-app', topbar: '.topbar', systemPanel: '.system-panel',
    controlsPanel: '.controls-panel', viewerHeading: '.viewer-heading', viewer: '#viewer',
    canvas: '#anatomyCanvas', infoCard: '#infoCard', bottomNav: '.bottom-nav'
  };

  const round = number => Math.round(number * 10) / 10;
  function snapshot(selector) {
    const element = document.querySelector(selector);
    if (!element) return { exists: false, visible: false, inViewport: false };
    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    const visible = style.display !== 'none' && style.visibility !== 'hidden' && Number(style.opacity || 1) > 0 && rect.width > 0 && rect.height > 0;
    const inViewport = visible && rect.left >= -1 && rect.top >= -1 && rect.right <= innerWidth + 1 && rect.bottom <= innerHeight + 1;
    return { exists: true, visible, inViewport, rect: { left: round(rect.left), top: round(rect.top), right: round(rect.right), bottom: round(rect.bottom), width: round(rect.width), height: round(rect.height) } };
  }

  function buildReport() {
    const bodyText = document.body.textContent || '';
    const elements = Object.fromEntries(Object.entries(targets).map(([key, selector]) => [key, snapshot(selector)]));
    const requiredVisible = ['topbar', 'systemPanel', 'controlsPanel', 'viewerHeading', 'viewer', 'canvas', 'infoCard', 'bottomNav'];
    const missingLabels = requiredLabels.filter(label => !bodyText.includes(label));
    const forbiddenPresent = forbiddenLabels.filter(label => bodyText.includes(label));
    const invisible = requiredVisible.filter(key => !elements[key]?.visible);
    const outsideViewport = requiredVisible.filter(key => !elements[key]?.inViewport);
    const loading = document.getElementById('loading');
    const loadingHidden = !loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none';
    const canvasRect = elements.canvas?.rect || { width: 0, height: 0 };
    const canvasUsable = canvasRect.width >= 170 && canvasRect.height >= 270;
    const noHorizontalOverflow = document.documentElement.scrollWidth <= innerWidth + 2;
    const noVerticalOverflow = document.documentElement.scrollHeight <= innerHeight + 2;
    const fitSelectors = ['.system-btn', '.controls-panel button', '.tabs', '.tab'];
    const clippedControls = [...document.querySelectorAll(fitSelectors.join(','))]
      .filter(element => element.scrollWidth > element.clientWidth + 1 || element.scrollHeight > element.clientHeight + 1)
      .map(element => ({ text: (element.textContent || '').replace(/\s+/g, ' ').trim(), client: [element.clientWidth, element.clientHeight], scroll: [element.scrollWidth, element.scrollHeight] }));
    const controlsClearBottomNav = (elements.controlsPanel?.rect?.bottom || Infinity) <= (elements.bottomNav?.rect?.top || -Infinity) + 1;
    const bicepsDefault = (document.getElementById('structureName')?.textContent || '').toLowerCase().includes('biceps brachii');
    const activeSystem = document.querySelector('.system-btn.active')?.dataset.system === 'muscle';
    const simplifiedDom = !document.querySelector('#examBtn, #quizCard, .learn-chip, .view-panel, .tool-panel');
    const pass = missingLabels.length === 0 && forbiddenPresent.length === 0 && invisible.length === 0 && outsideViewport.length === 0 &&
      loadingHidden && canvasUsable && noHorizontalOverflow && noVerticalOverflow && clippedControls.length === 0 &&
      controlsClearBottomNav && bicepsDefault && activeSystem && simplifiedDom;
    return {
      pass, elapsed_ms: Math.round(performance.now() - started),
      viewport: { width: innerWidth, height: innerHeight, dpr: devicePixelRatio },
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      loadingHidden, canvasUsable, noHorizontalOverflow, noVerticalOverflow, clippedControls, controlsClearBottomNav,
      bicepsDefault, activeSystem, simplifiedDom, missingLabels, forbiddenPresent, invisible, outsideViewport, elements
    };
  }

  function publish() {
    const report = buildReport();
    const pre = Object.assign(document.createElement('pre'), { id: 'qa-layout-report' });
    pre.setAttribute('aria-hidden', 'true');
    pre.style.cssText = 'position:absolute;left:-10000px;top:0;width:1px;height:1px;overflow:hidden;';
    pre.dataset.pass = String(report.pass);
    pre.textContent = JSON.stringify(report);
    document.body.appendChild(pre);
    document.documentElement.dataset.qaReady = 'true';
  }

  const timer = setInterval(() => {
    const loading = document.getElementById('loading');
    const ready = !loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none';
    if (ready || performance.now() - started >= deadlineMs) {
      clearInterval(timer);
      requestAnimationFrame(() => requestAnimationFrame(publish));
    }
  }, 200);
}
