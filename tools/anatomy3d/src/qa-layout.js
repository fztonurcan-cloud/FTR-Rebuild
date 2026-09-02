const params = new URLSearchParams(window.location.search);

if (params.get('qa') === '1') {
  const started = performance.now();
  const deadlineMs = 30000;

  const lockedLabels = [
    '3D ANATOMİ',
    'Sınav Modu',
    'Karma Sınav',
    'Kas Sistemi',
    'Sinir Sistemi',
    'Ligament Sistemi',
    'Damar Sistemi',
    'GÖRÜNÜM',
    'Tümü',
    'Kaslar',
    'Kemikler',
    'Damarlar',
    'Sinirler',
    'KONTROLLER',
    'Döndür',
    'Yakınlaştır',
    'Uzaklaştır',
    'Sıfırla',
    'Öğrenme Modu',
    'Etiketler',
    'Not Ekle',
    'Ekran',
    'Görüntüsü',
    'Bilgiyi',
    'Paylaş',
    'Biceps brachii',
    'İki başlı kol kası',
    'Genel Bilgi',
    'Origo',
    'Insertio',
    'İnnervasyon',
    'Fonksiyon'
  ];

  const targets = {
    app: '#anatomy-app',
    topbar: '.topbar',
    systemPanel: '.system-panel',
    viewPanel: '.view-panel',
    controlsPanel: '.controls-panel',
    viewerHeading: '.viewer-heading',
    viewer: '#viewer',
    canvas: '#anatomyCanvas',
    rightTools: '.tool-panel',
    infoCard: '#infoCard',
    bottomNav: '.bottom-nav'
  };

  function round(n) {
    return Math.round(n * 10) / 10;
  }

  function snapshot(selector) {
    const el = document.querySelector(selector);
    if (!el) return { exists: false, visible: false, inViewport: false };
    const r = el.getBoundingClientRect();
    const cs = getComputedStyle(el);
    const visible = cs.display !== 'none' && cs.visibility !== 'hidden' && Number(cs.opacity || 1) > 0 && r.width > 0 && r.height > 0;
    const inViewport = visible && r.left >= -1 && r.top >= -1 && r.right <= window.innerWidth + 1 && r.bottom <= window.innerHeight + 1;
    return {
      exists: true,
      visible,
      inViewport,
      rect: { left: round(r.left), top: round(r.top), right: round(r.right), bottom: round(r.bottom), width: round(r.width), height: round(r.height) }
    };
  }

  function buildReport() {
    const bodyText = document.body.textContent || '';
    const elements = Object.fromEntries(Object.entries(targets).map(([key, selector]) => [key, snapshot(selector)]));
    const loading = document.getElementById('loading');
    const loadingHidden = !loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none';
    const missingLabels = lockedLabels.filter(label => !bodyText.includes(label));
    const requiredVisible = ['topbar', 'systemPanel', 'viewPanel', 'controlsPanel', 'viewerHeading', 'viewer', 'canvas', 'rightTools', 'infoCard', 'bottomNav'];
    const invisible = requiredVisible.filter(key => !elements[key]?.visible);
    const outsideViewport = requiredVisible.filter(key => !elements[key]?.inViewport);
    const canvasRect = elements.canvas?.rect || { width: 0, height: 0 };
    const noHorizontalOverflow = document.documentElement.scrollWidth <= window.innerWidth + 2;
    const noVerticalOverflow = document.documentElement.scrollHeight <= window.innerHeight + 8;
    const canvasUsable = canvasRect.width >= 120 && canvasRect.height >= 400;
    const bicepsDefault = (document.getElementById('structureName')?.textContent || '').trim().toLowerCase().includes('biceps brachii');
    const activeSystem = (document.querySelector('.system-btn.active')?.textContent || '').includes('Kas Sistemi');
    const fitSelectors = ['.system-btn', '.view-btn', '.controls-panel button', '.tool-panel button', '.tabs', '.tab'];
    const clippedControls = [...document.querySelectorAll(fitSelectors.join(','))]
      .filter(el => el.scrollWidth > el.clientWidth + 1 || el.scrollHeight > el.clientHeight + 1)
      .map(el => ({
        selector: el.className || el.id || el.tagName,
        text: (el.textContent || '').replace(/\s+/g, ' ').trim(),
        client: [el.clientWidth, el.clientHeight],
        scroll: [el.scrollWidth, el.scrollHeight]
      }));
    const controlsClearBottomNav =
      (elements.controlsPanel?.rect?.bottom || Infinity) <= (elements.bottomNav?.rect?.top || -Infinity) + 1;

    const pass = missingLabels.length === 0 && invisible.length === 0 && outsideViewport.length === 0 &&
      noHorizontalOverflow && noVerticalOverflow && canvasUsable && bicepsDefault && activeSystem &&
      loadingHidden && clippedControls.length === 0 && controlsClearBottomNav;

    return {
      pass,
      elapsed_ms: Math.round(performance.now() - started),
      viewport: { width: window.innerWidth, height: window.innerHeight, dpr: window.devicePixelRatio },
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      noHorizontalOverflow,
      noVerticalOverflow,
      canvasUsable,
      loadingHidden,
      bicepsDefault,
      activeSystem,
      clippedControls,
      controlsClearBottomNav,
      missingLabels,
      invisible,
      outsideViewport,
      elements
    };
  }

  function publish() {
    const report = buildReport();
    let pre = document.getElementById('qa-layout-report');
    if (!pre) {
      pre = document.createElement('pre');
      pre.id = 'qa-layout-report';
      pre.setAttribute('aria-hidden', 'true');
      pre.style.cssText = 'position:absolute;left:-10000px;top:0;width:1px;height:1px;overflow:hidden;white-space:pre-wrap;';
      document.body.appendChild(pre);
    }
    pre.dataset.pass = String(report.pass);
    pre.textContent = JSON.stringify(report);
    document.documentElement.dataset.qaReady = 'true';
    return report;
  }

  const timer = setInterval(() => {
    const loading = document.getElementById('loading');
    const ready = !loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none';
    const expired = performance.now() - started >= deadlineMs;
    if (ready || expired) {
      clearInterval(timer);
      requestAnimationFrame(() => requestAnimationFrame(publish));
    }
  }, 250);
}
