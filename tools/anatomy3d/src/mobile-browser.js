const app = document.getElementById('anatomy-app');
const toggle = document.getElementById('structureToggleBtn');
const close = document.getElementById('structureCloseBtn');
const backdrop = document.getElementById('structureBackdrop');
const browser = document.getElementById('structureBrowser');
const list = document.getElementById('structureList');
const mobile = matchMedia('(max-width: 760px)');

function setOpen(open) {
  const next = Boolean(open && mobile.matches);
  app?.classList.toggle('structure-open', next);
  toggle?.setAttribute('aria-expanded', String(next));
  browser?.setAttribute('aria-hidden', String(mobile.matches && !next));
  document.documentElement.classList.toggle('anatomy-drawer-open', next);
}

function closeDrawer() { setOpen(false); }

if (toggle && close && backdrop && browser) {
  toggle.addEventListener('click', () => setOpen(!app.classList.contains('structure-open')));
  close.addEventListener('click', closeDrawer);
  backdrop.addEventListener('click', closeDrawer);
  list?.addEventListener('click', event => {
    if (event.target.closest('.structure-row')) closeDrawer();
  });
  document.querySelectorAll('.system-btn').forEach(button => button.addEventListener('click', closeDrawer));
  addEventListener('keydown', event => {
    if (event.key === 'Escape') closeDrawer();
  });
  mobile.addEventListener?.('change', closeDrawer);
  setOpen(false);
}
