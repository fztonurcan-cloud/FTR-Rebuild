const params = new URLSearchParams(location.search);

if (params.get('qa') === '1') {
  const started = performance.now();
  const deadlineMs = 120000;
  const requiredLabels = [
    '3D ANATOMİ', 'Kaslar', 'Kemikler', 'Ligamentler', 'Damarlar', 'Sinirler', 'Yapılar',
    'Biceps brachii', 'Genel Bilgi', 'Bir yapıya dokununca model üzerinde vurgulanır.'
  ];
  const forbiddenLabels = [
    'Sınav Modu', 'Karma Sınav', 'Öğrenme Modu', 'Etiketler', 'Not Ekle', 'Bilgiyi Paylaş',
    'Döndür', 'Yakınlaştır', 'Uzaklaştır', 'Otomatik Döndür'
  ];
  const targets = {
    app: '#anatomy-app',
    topbar: '.topbar',
    systemTabs: '.system-tabs',
    browser: '.structure-browser',
    structureToggle: '#structureToggleBtn',
    viewer: '#viewer',
    canvas: '#anatomyCanvas',
    infoCard: '#infoCard'
  };

  const round = number => Math.round(number * 10) / 10;
  function snapshot(selector) {
    const element = document.querySelector(selector);
    if (!element) return { exists: false, visible: false };
    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    const visible = style.display !== 'none' && style.visibility !== 'hidden' && Number(style.opacity || 1) > 0 && rect.width > 0 && rect.height > 0;
    return {
      exists: true,
      visible,
      rect: {
        left: round(rect.left), top: round(rect.top), right: round(rect.right), bottom: round(rect.bottom),
        width: round(rect.width), height: round(rect.height)
      }
    };
  }

  function buildReport() {
    const bodyText = document.body.textContent || '';
    const elements = Object.fromEntries(Object.entries(targets).map(([key, selector]) => [key, snapshot(selector)]));
    const missingLabels = requiredLabels.filter(label => !bodyText.includes(label));
    const forbiddenPresent = forbiddenLabels.filter(label => bodyText.includes(label));
    const isMobile = innerWidth <= 760;
    const requiredVisible = isMobile
      ? ['app', 'topbar', 'systemTabs', 'structureToggle', 'viewer', 'canvas', 'infoCard']
      : ['app', 'topbar', 'systemTabs', 'browser', 'viewer', 'canvas', 'infoCard'];
    const invisible = requiredVisible.filter(key => !elements[key]?.visible);

    const loading = document.getElementById('loading');
    const loadingHidden = !loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none';
    const canvasRect = elements.canvas?.rect || { width: 0, height: 0 };
    const mobileMinHeight = innerWidth <= 365 ? 560 : 590;
    const canvasUsable = isMobile
      ? canvasRect.width >= innerWidth - 24 && canvasRect.height >= mobileMinHeight
      : canvasRect.width >= 145 && canvasRect.height >= 490;
    const noHorizontalOverflow = document.documentElement.scrollWidth <= innerWidth + 2;
    const systemCount = document.querySelectorAll('.system-btn').length;
    const uniqueSystems = new Set([...document.querySelectorAll('.system-btn')].map(button => button.dataset.system)).size;
    const bicepsDefault = (document.getElementById('structureName')?.textContent || '').toLowerCase().includes('biceps brachii');
    const activeSystem = document.querySelector('.system-btn.active')?.dataset.system === 'muscle';
    const state = window.__FTR_ANATOMY_QA__?.state?.() || {};
    const staticAtlas = state.renderMode === 'static-layered-atlas' && state.webgl === false && state.runtime3dModels === false && state.continuousAnimation === false;
    const noLegacyControls = !document.querySelector('.viewer-controls, #rotateBtn, #zoomInBtn, #zoomOutBtn, #autoRotateBtn');

    const browserHiddenOnMobile = !isMobile || !elements.browser?.visible;
    const drawerClosed = !isMobile || document.getElementById('structureToggleBtn')?.getAttribute('aria-expanded') === 'false';
    const fullWidthMobileAtlas = !isMobile || canvasRect.width >= innerWidth - 24;
    const premiumMobile = browserHiddenOnMobile && drawerClosed && fullWidthMobileAtlas;

    const pass = missingLabels.length === 0 && forbiddenPresent.length === 0 && invisible.length === 0 && loadingHidden &&
      canvasUsable && noHorizontalOverflow && systemCount === 5 && uniqueSystems === 5 && bicepsDefault && activeSystem &&
      staticAtlas && noLegacyControls && premiumMobile;

    return {
      pass,
      elapsed_ms: Math.round(performance.now() - started),
      viewport: { width: innerWidth, height: innerHeight, dpr: devicePixelRatio },
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      loadingHidden, canvasUsable, noHorizontalOverflow, systemCount, uniqueSystems, bicepsDefault, activeSystem,
      staticAtlas, noLegacyControls, isMobile, browserHiddenOnMobile, drawerClosed, fullWidthMobileAtlas, premiumMobile,
      state, missingLabels, forbiddenPresent, invisible, elements
    };
  }

  function publish() {
    if (document.getElementById('qa-layout-report')) return;
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
    const state = window.__FTR_ANATOMY_QA__?.state?.() || {};
    const ready = state.imageReady && (!loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none');
    if (ready || performance.now() - started >= deadlineMs) {
      clearInterval(timer);
      requestAnimationFrame(() => requestAnimationFrame(publish));
    }
  }, 200);
}
