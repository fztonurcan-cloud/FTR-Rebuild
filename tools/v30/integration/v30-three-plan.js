(() => {
  'use strict';
  if (window.__FTR_V30_THREE_PLAN_HOME__) return;
  window.__FTR_V30_THREE_PLAN_HOME__ = true;

  const SHELL_SELECTOR = '.v56-home-shell.ftr-a3d-v56-installed';
  const INSTALL_CLASS = 'ftr-v30-three-plan-installed';
  const CARD_ID = 'ftr-v30-clinical-home-card';
  const BRAND_ID = 'ftr-v30-home-brand';
  const TAIL_CLASS = 'ftr-v30-reference-tail';

  function clinicalCardMarkup() {
    return `
      <button id="${CARD_ID}" class="ftr-v30-clinical-card" type="button" aria-label="Klinik Ölçekler modülünü aç">
        <span class="ftr-v30-clinical-icon" aria-hidden="true">
          <svg viewBox="0 0 48 48" focusable="false">
            <rect x="12" y="9" width="24" height="31" rx="4"/>
            <path d="M19 9v-2h10v2M18 18h12M18 24h12M18 30h8"/>
            <path class="ftr-v30-clinical-check" d="m28 32 3 3 6-7"/>
          </svg>
        </span>
        <span class="ftr-v30-clinical-copy">
          <span class="ftr-v30-clinical-title">Klinik Ölçekler <em>YENİ</em></span>
          <span class="ftr-v30-clinical-sub">Testler, skorlamalar ve değerlendirme araçları</span>
        </span>
        <span class="ftr-v30-clinical-arrow" aria-hidden="true">›</span>
      </button>`;
  }

  function brandMarkup() {
    return `
      <button id="${BRAND_ID}" class="ftr-v30-home-brand" type="button" aria-label="FTR Akademi ana sayfası">
        <img src="./brand/ftr-logo-exact.png" alt="" aria-hidden="true">
        <span>FTR AKADEMİ</span>
      </button>`;
  }

  function install() {
    const shell = document.querySelector(SHELL_SELECTOR);
    if (!shell || shell.classList.contains(INSTALL_CLASS)) return false;

    const middle = shell.querySelector(':scope > .ftr-a3d-v56-reference-bottom');
    if (!middle) return false;

    shell.classList.add(INSTALL_CLASS);
    middle.classList.add('ftr-v30-reference-middle');

    const tail = middle.cloneNode(false);
    tail.classList.remove('ftr-a3d-v56-reference-bottom', 'ftr-v30-reference-middle');
    tail.classList.add(TAIL_CLASS);
    tail.setAttribute('aria-hidden', 'true');
    middle.insertAdjacentElement('afterend', tail);
    tail.insertAdjacentHTML('afterend', clinicalCardMarkup());
    shell.insertAdjacentHTML('beforeend', brandMarkup());

    const clinical = shell.querySelector(`#${CARD_ID}`);
    const brand = shell.querySelector(`#${BRAND_ID}`);
    clinical.addEventListener('click', () => {
      window.location.href = './clinical-scales/index.html';
    });
    brand.addEventListener('click', () => {
      window.location.href = './index.html';
    });
    return true;
  }

  install();
  const observer = new MutationObserver(install);
  observer.observe(document.documentElement, {childList: true, subtree: true});
})();
