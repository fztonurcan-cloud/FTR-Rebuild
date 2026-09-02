(() => {
  'use strict';
  if (window.__FTR_3D_ANATOMY_HOME__) return;
  window.__FTR_3D_ANATOMY_HOME__ = true;

  const CARD_ID = 'ftr-anatomy3d-home-section';

  function cardMarkup() {
    return `
      <button id="${CARD_ID}" class="ftr-a3d-v56-card" type="button" aria-label="3D Anatomi modülünü aç">
        <span class="ftr-a3d-v56-copy">
          <span class="ftr-a3d-v56-title">3D ANATOMİ <em>YENİ</em></span>
          <span class="ftr-a3d-v56-sub">Kaslar • Sinirler • Ligamentler • Damarlar</span>
          <span class="ftr-a3d-v56-note">3D model üzerinde keşfet, öğren ve sınav ol!</span>
          <span class="ftr-a3d-v56-cta">Keşfetmeye Başla <b>→</b></span>
        </span>
        <span class="ftr-a3d-v56-figure" aria-hidden="true">
          <svg viewBox="0 0 72 126" focusable="false">
            <circle cx="36" cy="13" r="10"/>
            <path d="M29 12h14M31 17h10M36 23v55M24 33c7-7 17-7 24 0M22 39c9 7 19 7 28 0M24 46c8 6 16 6 24 0M27 53c6 4 12 4 18 0M36 27L18 58M36 27l18 31M18 58l-7 27M54 58l7 27M36 78l-14 39M36 78l14 39M18 85l-5 24M54 85l5 24"/>
            <path class="ftr-a3d-v56-muscle" d="M25 31c-8 9-10 22-7 31M47 31c8 9 10 22 7 31M29 80l-7 35M43 80l7 35"/>
          </svg>
        </span>
        <span class="ftr-a3d-v56-systems" aria-hidden="true">
          <span><i class="muscle">◒</i>Kas Sistemi <b>›</b></span>
          <span><i class="nerve">✳</i>Sinir Sistemi <b>›</b></span>
          <span><i class="ligament">✦</i>Ligament Sistemi <b>›</b></span>
          <span><i class="vessel">⌬</i>Damar Sistemi <b>›</b></span>
        </span>
      </button>`;
  }

  function install() {
    const shell = document.querySelector('.v56-home-shell');
    if (!shell || shell.classList.contains('ftr-a3d-v56-installed')) return false;
    const original = shell.querySelector(':scope > .v56-home-reference');
    if (!original) return false;

    shell.classList.add('ftr-a3d-v56-installed');
    original.classList.add('ftr-a3d-v56-reference-top');
    const lower = original.cloneNode(false);
    lower.removeAttribute('alt');
    lower.setAttribute('aria-hidden', 'true');
    lower.classList.remove('ftr-a3d-v56-reference-top');
    lower.classList.add('ftr-a3d-v56-reference-bottom');
    original.insertAdjacentElement('afterend', lower);
    lower.insertAdjacentHTML('afterend', cardMarkup());
    shell.querySelector(`#${CARD_ID}`).addEventListener('click', () => {
      window.location.href = './anatomy3d/index.html';
    });
    return true;
  }

  install();
  const observer = new MutationObserver(install);
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
