(() => {
  'use strict';
  const app = document.getElementById('clinicalApp');
  const filter = document.getElementById('filterBtn');
  const tools = document.getElementById('catalogTools');

  if (filter && tools) {
    filter.addEventListener('click', () => {
      const open = !app.classList.contains('filters-open');
      app.classList.toggle('filters-open', open);
      filter.setAttribute('aria-expanded', String(open));
      filter.setAttribute('aria-label', open ? 'Filtreleri kapat' : 'Filtreleri aç');
    });
  }

  document.querySelector('.clinical-bottom-nav')?.addEventListener('click', event => {
    const button = event.target.closest('button[data-host-nav]');
    if (!button) return;
    const route = button.dataset.hostNav;
    if (route === 'home') {
      window.location.href = '../index.html';
      return;
    }
    window.location.href = `../index.html?v30nav=${encodeURIComponent(route)}`;
  });
})();
