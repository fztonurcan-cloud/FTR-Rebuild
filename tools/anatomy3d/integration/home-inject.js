(() => {
  'use strict';
  if (window.__FTR_3D_ANATOMY_HOME__) return;
  window.__FTR_3D_ANATOMY_HOME__ = true;

  const CARD_ID = 'ftr-anatomy3d-home-section';
  const STUDIO_RE = /HAREKET\s*ST[ÜU]DYOSU/i;

  function text(el) { return (el && el.textContent || '').replace(/\s+/g, ' ').trim(); }
  function visible(el) {
    if (!el) return false;
    const s = getComputedStyle(el);
    const r = el.getBoundingClientRect();
    return s.display !== 'none' && s.visibility !== 'hidden' && r.width > 10 && r.height > 8;
  }
  function studioAnchor() {
    const all = [...document.querySelectorAll('body *')];
    const hits = all.filter(el => visible(el) && STUDIO_RE.test(text(el)) && text(el).length < 120);
    for (const hit of hits) {
      let node = hit;
      for (let i = 0; i < 7 && node && node.parentElement; i++, node = node.parentElement) {
        const t = text(node);
        const r = node.getBoundingClientRect();
        if (STUDIO_RE.test(t) && /St[üu]dyoya\s*Gir/i.test(t) && r.width > 220 && r.height > 90) return node;
      }
    }
    return hits[0]?.parentElement || null;
  }
  function createCard() {
    const section = document.createElement('section');
    section.id = CARD_ID;
    section.className = 'ftr-a3d-home';
    section.innerHTML = `
      <div class="ftr-a3d-kicker"><span class="ftr-a3d-kicker-icon">⌬</span><strong>3D ANATOMİ</strong><span class="ftr-a3d-new">YENİ</span></div>
      <button class="ftr-a3d-card" type="button" aria-label="3D Anatomi modülünü aç">
        <div class="ftr-a3d-copy">
          <h3>3D ANATOMİ</h3>
          <p>Kaslar • Sinirler • Ligamentler • Damarlar</p>
          <small>3D model üzerinde keşfet, öğren ve sınav ol!</small>
          <span class="ftr-a3d-cta">Keşfetmeye Başla <b>→</b></span>
        </div>
        <div class="ftr-a3d-body" aria-hidden="true">
          <span class="ftr-a3d-skull">◉</span>
          <span class="ftr-a3d-spine">││</span>
          <span class="ftr-a3d-ribs">≋</span>
        </div>
        <div class="ftr-a3d-systems" aria-hidden="true">
          <span><i class="m">◒</i>Kas</span><span><i class="n">✳</i>Sinir</span><span><i class="l">✦</i>Ligament</span><span><i class="v">⌬</i>Damar</span>
        </div>
      </button>`;
    section.querySelector('.ftr-a3d-card').addEventListener('click', () => {
      window.location.href = './anatomy3d/index.html';
    });
    return section;
  }
  function install() {
    if (document.getElementById(CARD_ID)) return true;
    const anchor = studioAnchor();
    if (!anchor || !anchor.parentElement) return false;
    anchor.parentElement.insertBefore(createCard(), anchor);
    return true;
  }
  if (!install()) {
    const observer = new MutationObserver(() => { if (install()) observer.disconnect(); });
    observer.observe(document.documentElement, { childList: true, subtree: true });
    setTimeout(() => observer.disconnect(), 15000);
  }
})();
