(() => {
  'use strict';
  if (window.__FTR_V30_THREE_PLAN_HOME__) return;
  window.__FTR_V30_THREE_PLAN_HOME__ = true;

  const SHELL_SELECTOR = '.v56-home-shell.ftr-a3d-v56-installed';
  const INSTALL_CLASS = 'ftr-v30-three-plan-installed';
  const PREMIUM_ID = 'ftr-v30-premium-home';
  const DRAWER_ID = 'ftr-v30-premium-drawer';

  const icon = name => ({
    courses:'▣', anatomy:'☠', movement:'♿', clinical:'▤',
    quiz:'?', favorite:'☆', note:'▧', program:'▦',
    home:'⌂', workspace:'♧', profile:'♙', settings:'⚙', help:'?', logout:'⇥'
  }[name] || '•');

  function markup() {
    return `
      <section id="${PREMIUM_ID}" class="ftr-v30-premium-home" aria-label="FTR Akademi ana sayfa">
        <header class="ftr-v30-premium-topbar">
          <button class="ftr-v30-icon-btn" type="button" data-v30-action="drawer" aria-label="Menüyü aç">☰</button>
          <button class="ftr-v30-premium-brand" type="button" data-v30-route="home" aria-label="FTR Akademi ana sayfası">
            <img src="./brand/ftr-logo-exact.png" alt="" aria-hidden="true"><span>FTR AKADEMİ</span>
          </button>
          <button class="ftr-v30-icon-btn ftr-v30-bell" type="button" data-v30-route="notifications" aria-label="Bildirimler">♧<i></i></button>
        </header>

        <section class="ftr-v30-premium-hero">
          <div class="ftr-v30-premium-greeting">
            <h1>Merhaba, Fizyoterapist! <span>👋</span></h1>
            <p>Bugün kendini geliştirmek için<br>harika bir gün.</p>
          </div>
          <img class="ftr-v30-hero-anatomy" src="./anatomy3d/atlas/muscle-front.png" alt="" aria-hidden="true">
        </section>

        <h2 class="ftr-v30-section-title">Hızlı Erişim</h2>
        <div class="ftr-v30-module-stack">
          <button class="ftr-v30-module-card courses" type="button" data-v30-route="courses">
            <span class="ftr-v30-module-icon">${icon('courses')}</span><span><b>Derslerim</b><small>Konu anlatımları ve içerikler</small></span><em>›</em>
          </button>
          <button class="ftr-v30-module-card anatomy" type="button" data-v30-route="anatomy">
            <span class="ftr-v30-module-icon">${icon('anatomy')}</span><span><b>3D Anatomi</b><small>Kaslar, kemikler, ligamentler ve daha fazlası</small></span><em>›</em>
          </button>
          <button class="ftr-v30-module-card movement" type="button" data-v30-route="movement">
            <span class="ftr-v30-module-icon">${icon('movement')}</span><span><b>Hareket Stüdyosu</b><small>Egzersizler, programlar ve videolar</small></span><em>›</em>
          </button>
          <button class="ftr-v30-module-card clinical" type="button" data-v30-route="clinical">
            <span class="ftr-v30-module-icon">${icon('clinical')}</span><span><b>Klinik Ölçekler <mark>YENİ</mark></b><small>Testler, skorlamalar ve değerlendirme araçları</small></span><em>›</em>
          </button>
        </div>

        <h2 class="ftr-v30-section-title ftr-v30-shortcuts-title">Kısayollarım</h2>
        <div class="ftr-v30-shortcuts">
          <button type="button" data-v30-route="quiz"><span>${icon('quiz')}</span><small>Quizler</small></button>
          <button type="button" data-v30-route="favorites"><span>${icon('favorite')}</span><small>Favoriler</small></button>
          <button type="button" data-v30-route="notes"><span>${icon('note')}</span><small>Notlarım</small></button>
          <button type="button" data-v30-route="programs"><span>${icon('program')}</span><small>Programlarım</small></button>
        </div>

        <nav class="ftr-v30-bottom-nav" aria-label="Ana navigasyon">
          <button class="active" type="button" data-v30-route="home"><span>${icon('home')}</span><small>Ana Sayfa</small></button>
          <button type="button" data-v30-route="courses"><span>${icon('courses')}</span><small>Dersler</small></button>
          <button type="button" data-v30-route="workspace"><span>${icon('workspace')}</span><small>Çalışma Alanım</small></button>
          <button type="button" data-v30-route="profile"><span>${icon('profile')}</span><small>Profilim</small></button>
        </nav>

        <div id="${DRAWER_ID}" class="ftr-v30-drawer-layer" hidden>
          <button class="ftr-v30-drawer-scrim" type="button" data-v30-action="close-drawer" aria-label="Menüyü kapat"></button>
          <aside class="ftr-v30-drawer" aria-label="FTR Akademi menü">
            <div class="ftr-v30-drawer-brand">
              <img src="./brand/ftr-logo-exact.png" alt="" aria-hidden="true">
              <div><b>FTR AKADEMİ</b><small>Fizyoterapi Bilgi Platformu</small></div>
            </div>
            <nav>
              <button class="active" type="button" data-v30-route="home"><i>${icon('home')}</i>Ana Sayfa</button>
              <button type="button" data-v30-route="courses"><i>${icon('courses')}</i>Derslerim</button>
              <button type="button" data-v30-route="anatomy"><i>${icon('anatomy')}</i>3D Anatomi</button>
              <button type="button" data-v30-route="movement"><i>${icon('movement')}</i>Hareket Stüdyosu</button>
              <button type="button" data-v30-route="clinical"><i>${icon('clinical')}</i>Klinik Ölçekler <mark>YENİ</mark></button>
              <hr>
              <button type="button" data-v30-route="workspace"><i>${icon('workspace')}</i>Çalışma Alanım</button>
              <button type="button" data-v30-route="notes"><i>${icon('note')}</i>Notlarım</button>
              <button type="button" data-v30-route="favorites"><i>${icon('favorite')}</i>Favorilerim</button>
              <button type="button" data-v30-route="programs"><i>${icon('program')}</i>Programlarım</button>
              <hr>
              <button type="button" data-v30-route="settings"><i>${icon('settings')}</i>Ayarlar</button>
              <button type="button" data-v30-route="help"><i>${icon('help')}</i>Yardım & Destek</button>
              <button type="button" data-v30-route="logout"><i>${icon('logout')}</i>Çıkış Yap</button>
            </nav>
          </aside>
        </div>
      </section>`;
  }

  function legacyClick(selectors) {
    for (const selector of selectors) {
      const target = document.querySelector(selector);
      if (target && !target.closest(`#${PREMIUM_ID}`)) {
        target.click();
        return true;
      }
    }
    return false;
  }

  function legacyTextClick(labels) {
    const normalized = labels.map(x => x.toLocaleLowerCase('tr-TR'));
    const nodes = [...document.querySelectorAll('button,a,[role="button"]')];
    const target = nodes.find(node => {
      if (node.closest(`#${PREMIUM_ID}`)) return false;
      const text = (node.textContent || node.getAttribute('aria-label') || '').trim().toLocaleLowerCase('tr-TR');
      return normalized.some(label => text.includes(label));
    });
    if (!target) return false;
    target.click();
    return true;
  }

  function closeDrawer() {
    const layer = document.getElementById(DRAWER_ID);
    if (layer) layer.hidden = true;
  }
  function openDrawer() {
    const layer = document.getElementById(DRAWER_ID);
    if (layer) layer.hidden = false;
  }

  function route(name) {
    closeDrawer();
    if (name === 'home') return;
    if (name === 'anatomy') { window.location.href = './anatomy3d/index.html'; return; }
    if (name === 'clinical') { window.location.href = './clinical-scales/index.html'; return; }
    if (name === 'courses' && legacyClick(['.v56-hot-allclasses','.v56-hot-nav-courses'])) return;
    if (name === 'movement' && legacyClick(['.v56-hot-movement'])) return;
    if (name === 'workspace' && legacyClick(['.v56-hot-nav-search'])) return;
    if (name === 'profile' && legacyClick(['.v56-hot-nav-profile'])) return;
    if (name === 'notifications' && legacyTextClick(['bildirim'])) return;
    if (name === 'quiz' && legacyTextClick(['quiz'])) return;
    if (name === 'favorites' && legacyTextClick(['favori'])) return;
    if (name === 'notes' && legacyTextClick(['notlarım','notlar'])) return;
    if (name === 'programs' && legacyTextClick(['programlarım','programlar'])) return;
    if (name === 'settings' && legacyTextClick(['ayarlar'])) return;
    if (name === 'help' && legacyTextClick(['yardım','destek'])) return;
    if (name === 'logout' && legacyTextClick(['çıkış yap','oturumu kapat'])) return;
    if (['favorites','notes','programs'].includes(name)) legacyClick(['.v56-hot-nav-search']);
    else if (name === 'quiz') legacyClick(['.v56-hot-nav-courses']);
  }

  function install() {
    const shell = document.querySelector(SHELL_SELECTOR);
    if (!shell || shell.classList.contains(INSTALL_CLASS)) return false;
    shell.classList.add(INSTALL_CLASS);
    shell.insertAdjacentHTML('beforeend', markup());

    const premium = shell.querySelector(`#${PREMIUM_ID}`);
    premium.addEventListener('click', event => {
      const action = event.target.closest('[data-v30-action]')?.dataset.v30Action;
      if (action === 'drawer') { openDrawer(); return; }
      if (action === 'close-drawer') { closeDrawer(); return; }
      const routeName = event.target.closest('[data-v30-route]')?.dataset.v30Route;
      if (routeName) route(routeName);
    });
    return true;
  }

  install();
  const observer = new MutationObserver(install);
  observer.observe(document.documentElement, {childList:true, subtree:true});
})();
