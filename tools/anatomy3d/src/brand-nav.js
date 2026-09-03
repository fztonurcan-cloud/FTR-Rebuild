(() => {
  'use strict';

  const homeBrand = document.getElementById('anatomyHomeBrand');
  if (!homeBrand) throw new Error('Exact FTR brand Home control is missing');

  const goHome = () => {
    window.location.href = '../index.html';
  };

  homeBrand.addEventListener('click', goHome);

  // QA-only public state: no app data, no user data.
  window.__FTR_BRAND_QA__ = Object.freeze({
    exactAssetPath: '../brand/ftr-logo-exact.png',
    logoIsHomeControl: true,
    backIsHierarchical: true,
    goHome
  });
})();
