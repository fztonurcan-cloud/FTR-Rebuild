const params = new URLSearchParams(location.search);

if (params.get('qa') === '1') {
  const started = performance.now();
  const deadlineMs = 120000;
  const requiredLabels = [
    '3D ANATOMİ', 'Kaslar', 'Kemikler', 'Ligamentler', 'Damarlar', 'Sinirler',
    'Döndür', 'Yakınlaştır', 'Uzaklaştır', 'Sıfırla', 'Katmanlar', 'Şeffaflık',
    'Biceps brachii', 'Genel Bilgi'
  ];
  const forbiddenLabels = ['Sınav Modu', 'Karma Sınav', 'Öğrenme Modu', 'Etiketler', 'Not Ekle', 'Bilgiyi Paylaş'];
  const targets = {
    app: '#anatomy-app', topbar: '.topbar', systemTabs: '.system-tabs', browser: '.structure-browser',
    controls: '.viewer-controls', viewer: '#viewer', canvas: '#anatomyCanvas', infoCard: '#infoCard'
  };

  const round = number => Math.round(number * 10) / 10;
  function snapshot(selector) {
    const element = document.querySelector(selector);
    if (!element) return { exists: false, visible: false };
    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    const visible = style.display !== 'none' && style.visibility !== 'hidden' && Number(style.opacity || 1) > 0 && rect.width > 0 && rect.height > 0;
    return { exists: true, visible, rect: { left: round(rect.left), top: round(rect.top), right: round(rect.right), bottom: round(rect.bottom), width: round(rect.width), height: round(rect.height) } };
  }

  function buildReport() {
    const bodyText = document.body.textContent || '';
    const elements = Object.fromEntries(Object.entries(targets).map(([key, selector]) => [key, snapshot(selector)]));
    const missingLabels = requiredLabels.filter(label => !bodyText.includes(label));
    const forbiddenPresent = forbiddenLabels.filter(label => bodyText.includes(label));
    const invisible = Object.entries(elements).filter(([, value]) => !value.visible).map(([key]) => key);
    const loading = document.getElementById('loading');
    const loadingHidden = !loading || loading.classList.contains('hidden') || getComputedStyle(loading).display === 'none';
    const canvasRect = elements.canvas?.rect || { width: 0, height: 0 };
    const canvasUsable = canvasRect.width >= 150 && canvasRect.height >= 440;
    const noHorizontalOverflow = document.documentElement.scrollWidth <= innerWidth + 2;
    const systemCount = document.querySelectorAll('.system-btn').length;
    const uniqueSystems = new Set([...document.querySelectorAll('.system-btn')].map(button => button.dataset.system)).size;
    const bicepsDefault = (document.getElementById('structureName')?.textContent || '').toLowerCase().includes('biceps brachii');
    const activeSystem = document.querySelector('.system-btn.active')?.dataset.system === 'muscle';
    const legacyModesAbsent = !document.querySelector('#examBtn, #quizCard, .learn-chip, .tool-panel');
    const pass = missingLabels.length === 0 && forbiddenPresent.length === 0 && invisible.length === 0 && loadingHidden &&
      canvasUsable && noHorizontalOverflow && systemCount === 5 && uniqueSystems === 5 && bicepsDefault && activeSystem && legacyModesAbsent;
    return {
      pass,
      elapsed_ms: Math.round(performance.now() - started),
      viewport: { width: innerWidth, height: innerHeight, dpr: devicePixelRatio },
      document: { scrollWidth: document.documentElement.scrollWidth, scrollHeight: document.documentElement.scrollHeight },
      loadingHidden, canvasUsable, noHorizontalOverflow, systemCount, uniqueSystems, bicepsDefault, activeSystem,
      legacyModesAbsent, missingLabels, forbiddenPresent, invisible, elements
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
